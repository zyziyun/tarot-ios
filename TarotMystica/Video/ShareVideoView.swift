import SwiftUI
import AVKit
import Photos

/// Sheet view for generating and sharing a short video of the tarot reading
struct ShareVideoView: View {
    let question: String
    let spreadName: String
    let spreadKey: String?
    let drawnCards: [DrawnCard]
    let positions: [SpreadPosition]
    let aiReading: String
    let cardNameFn: (TarotCard) -> String

    @Environment(\.dismiss) private var dismiss

    @State private var state: GenerationState = .idle
    @State private var progress: Float = 0
    @State private var videoURL: URL?
    @State private var player: AVPlayer?
    @State private var showShareSheet = false
    @State private var savedToPhotos = false

    private enum GenerationState {
        case idle, generating, done, error(String)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.04, blue: 0.10)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    switch state {
                    case .idle:
                        idleView
                    case .generating:
                        generatingView
                    case .done:
                        doneView
                    case .error(let msg):
                        errorView(msg)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Share Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showShareSheet) {
                if let url = videoURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 0.788, green: 0.659, blue: 0.298).opacity(0.5))

            Text("Generate a 15-second video of your reading")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Text("Perfect for sharing on TikTok, Instagram, or WeChat")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.35))

            Spacer()

            Button {
                Task { await generateVideo() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "video.badge.plus")
                    Text("Generate Video")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color(red: 0.486, green: 0.227, blue: 0.929))
                .cornerRadius(28)
            }
        }
    }

    // MARK: - Generating

    private var generatingView: some View {
        VStack(spacing: 20) {
            Spacer()

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(Color(red: 0.486, green: 0.227, blue: 0.929))
                .frame(maxWidth: 240)

            Text("\(Int(progress * 100))%")
                .font(.system(size: 32, weight: .light, design: .monospaced))
                .foregroundColor(.white)

            Text("Rendering your reading...")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))

            Spacer()
        }
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 16) {
            // Video preview
            if let player {
                VideoPlayer(player: player)
                    .frame(maxWidth: 240, maxHeight: 426)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.5), radius: 20)
                    .onAppear { player.play() }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    saveToPhotos()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: savedToPhotos ? "checkmark" : "square.and.arrow.down")
                        Text(savedToPhotos ? "Saved" : "Save")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(20)
                }
                .disabled(savedToPhotos)

                Button {
                    showShareSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.486, green: 0.227, blue: 0.929))
                    .cornerRadius(20)
                }
            }
        }
    }

    // MARK: - Error

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundColor(.orange)
            Text(msg)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task { await generateVideo() }
            }
            .foregroundColor(Color(red: 0.486, green: 0.227, blue: 0.929))
            Spacer()
        }
    }

    // MARK: - Generation

    @MainActor
    private func generateVideo() async {
        state = .generating
        progress = 0

        let storyboard = VideoStoryboard.create(
            question: question,
            spreadName: spreadName,
            spreadKey: spreadKey,
            drawnCards: drawnCards,
            positions: positions,
            aiReading: aiReading,
            cardNameFn: cardNameFn
        )

        do {
            let composer = VideoComposer(storyboard: storyboard)
            let url = try await composer.generate { p in
                self.progress = p
            }
            self.progress = 1.0
            self.videoURL = url
            self.player = AVPlayer(url: url)
            self.player?.actionAtItemEnd = .none
            // Loop playback
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: self.player?.currentItem,
                queue: .main
            ) { _ in
                self.player?.seek(to: .zero)
                self.player?.play()
            }
            state = .done
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Save to Photos

    private func saveToPhotos() {
        guard let url = videoURL else { return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, _ in
                DispatchQueue.main.async {
                    if success { savedToPhotos = true }
                }
            }
        }
    }
}
