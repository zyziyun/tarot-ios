import Foundation
#if !targetEnvironment(simulator)
import MLX
import MLXLLM
import MLXLMCommon
#endif

/// Manages local LLM via MLX Swift: model selection, download, cache, load, streaming generation
/// MLX requires Metal GPU — only available on physical devices, not the Simulator.
@Observable
final class MLXService {

    enum ModelState: Equatable {
        case idle
        case downloading(progress: Double, text: String)
        case loading
        case ready
        case error(String)
    }

    var state: ModelState = .idle
    var loadedModelId: String?

    #if !targetEnvironment(simulator)
    private var modelContainer: ModelContainer?
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    #endif

    var isReady: Bool { state == .ready }
    var isLoading: Bool {
        switch state {
        case .downloading, .loading: return true
        default: return false
        }
    }

    // MARK: - Memory Management

    /// Device total RAM in bytes
    private static let totalRAMBytes = ProcessInfo.processInfo.physicalMemory
    /// Device total RAM in GB
    private static let totalRAMGB = Double(totalRAMBytes) / 1_073_741_824

    /// Max model size we allow (40% of total RAM — balanced between availability
    /// and safety; memory limits + pressure monitoring handle the rest)
    private static let maxModelFraction: Double = 0.40

    /// MLX memory limit: cap GPU allocations to prevent OS kill.
    /// On 8GB devices → ~2.4GB; on 6GB → ~1.8GB
    private static var mlxMemoryLimitBytes: Int {
        Int(Double(totalRAMBytes) * 0.30)
    }

    /// MLX cache limit: keep it small — large caches cause memory spikes.
    /// 128MB is plenty for inference; MLX docs say even 2MB works fine.
    private static let mlxCacheLimitBytes: Int = 128 * 1024 * 1024  // 128 MB

    init() {
        #if !targetEnvironment(simulator)
        configureMemoryLimits()
        startMemoryPressureMonitor()
        #endif
    }

    #if !targetEnvironment(simulator)
    /// Set conservative MLX memory limits to avoid OS jetsam kills
    private func configureMemoryLimits() {
        Memory.memoryLimit = Self.mlxMemoryLimitBytes
        Memory.cacheLimit = Self.mlxCacheLimitBytes
    }

    /// Monitor system memory pressure and unload model if critical
    private func startMemoryPressureMonitor() {
        let source = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            let event = source.data
            if event.contains(.critical) {
                // Critical: unload model immediately to avoid being killed
                #if DEBUG
                print("[MLXService] Critical memory pressure — unloading model")
                #endif
                self.unload()
            } else if event.contains(.warning) {
                // Warning: clear caches but keep model loaded
                #if DEBUG
                print("[MLXService] Memory pressure warning — clearing caches")
                #endif
                Memory.cacheLimit = 0          // flush cache
                Memory.cacheLimit = Self.mlxCacheLimitBytes  // restore limit
            }
        }
        source.resume()
        memoryPressureSource = source
    }
    #endif

    deinit {
        #if !targetEnvironment(simulator)
        memoryPressureSource?.cancel()
        #endif
    }

    // MARK: - Available models from providers.json

    struct LocalModel {
        let id: String
        let name: String
        let size: String
    }

    /// Filter models to only those safe for device memory
    static func availableModels(from providersConfig: DataLoader.ProvidersConfig) -> [LocalModel] {
        guard let iosList = providersConfig.localModels["ios"] as? [[String: Any]] else { return [] }

        // Safe model size limit: 25% of total RAM (conservative)
        let maxModelGB = totalRAMGB * maxModelFraction

        return iosList.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let name = dict["name"] as? String,
                  let size = dict["size"] as? String else { return nil }

            // Parse size string like "~1.5GB" to get GB value
            let sizeStr = size.replacingOccurrences(of: "~", with: "")
                .replacingOccurrences(of: "GB", with: "")
                .trimmingCharacters(in: .whitespaces)
            if let sizeGB = Double(sizeStr), sizeGB > maxModelGB {
                return nil  // Skip models too large for this device
            }

            return LocalModel(id: id, name: name, size: size)
        }
    }

    // MARK: - Load model (downloads if not cached)

    @MainActor
    func loadModel(_ modelId: String) async {
        #if targetEnvironment(simulator)
        state = .error("Local models require a physical device (Metal GPU)")
        #else
        if loadedModelId == modelId && state == .ready { return }
        unload()

        // Ensure memory limits are set before loading
        configureMemoryLimits()

        state = .downloading(progress: 0, text: "Preparing...")

        do {
            let config = ModelConfiguration(id: modelId)
            let container = try await LLMModelFactory.shared.loadContainer(
                configuration: config
            ) { [weak self] progress in
                Task { @MainActor [weak self] in
                    let pct = progress.fractionCompleted
                    if pct < 1.0 {
                        self?.state = .downloading(progress: pct, text: "Downloading... \(Int(pct * 100))%")
                    } else {
                        self?.state = .loading
                    }
                }
            }
            modelContainer = container
            loadedModelId = modelId
            state = .ready

            #if DEBUG
            let snap = Memory.snapshot()
            print("[MLXService] Model loaded. Active: \(snap.activeMemory / 1024 / 1024)MB, Cache: \(snap.cacheMemory / 1024 / 1024)MB, Peak: \(snap.peakMemory / 1024 / 1024)MB")
            #endif
        } catch {
            state = .error(error.localizedDescription)
        }
        #endif
    }

    // MARK: - Generate (streaming)

    func generate(
        messages: [APIExecutor.Message],
        temperature: Float = 0.7,
        onToken: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        #if targetEnvironment(simulator)
        throw LLMError.notConfigured
        #else
        guard let container = modelContainer else {
            throw LLMError.notConfigured
        }
        // Merge system messages into user messages to avoid Jinja template errors
        // with models that don't support the system role
        var merged: [APIExecutor.Message] = []
        var pendingSystem = ""
        for msg in messages {
            if msg.role == "system" {
                pendingSystem += (pendingSystem.isEmpty ? "" : "\n\n") + msg.content
            } else {
                if !pendingSystem.isEmpty {
                    merged.append(.init(role: msg.role, content: pendingSystem + "\n\n" + msg.content))
                    pendingSystem = ""
                } else {
                    merged.append(msg)
                }
            }
        }
        if !pendingSystem.isEmpty {
            merged.append(.init(role: "user", content: pendingSystem))
        }
        let chatMessages: [[String: String]] = merged.map {
            ["role": $0.role, "content": $0.content]
        }
        let result = try await container.perform { context in
            let input = try await context.processor.prepare(
                input: .init(messages: chatMessages)
            )
            return try MLXLMCommon.generate(
                input: input,
                parameters: GenerateParameters(
                    temperature: temperature,
                    repetitionPenalty: 1.3,
                    repetitionContextSize: 256
                ),
                context: context
            ) { tokens in
                let text = context.tokenizer.decode(tokens: tokens)
                onToken(text)
                // Limit to 1024 tokens to control memory (KV cache grows with length)
                if tokens.count >= 1024 { return .stop }
                return .more
            }
        }

        // Flush GPU cache after generation to free KV cache memory
        Memory.cacheLimit = 0
        Memory.cacheLimit = Self.mlxCacheLimitBytes

        #if DEBUG
        let snap = Memory.snapshot()
        print("[MLXService] Post-generate. Active: \(snap.activeMemory / 1024 / 1024)MB, Cache: \(snap.cacheMemory / 1024 / 1024)MB")
        #endif

        return result.output
        #endif
    }

    // MARK: - Unload

    func unload() {
        #if !targetEnvironment(simulator)
        modelContainer = nil
        // Flush all cached GPU memory
        Memory.cacheLimit = 0
        Memory.cacheLimit = Self.mlxCacheLimitBytes
        #endif
        loadedModelId = nil
        state = .idle
    }
}
