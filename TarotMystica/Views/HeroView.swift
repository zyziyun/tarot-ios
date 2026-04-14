import SwiftUI

struct HeroView: View {
    @Environment(AppState.self) private var state
    @Environment(LLMService.self) private var llm
    @Environment(LocalizationManager.self) private var i18n
    @Environment(ThemeManager.self) private var theme

    @State private var showSettings = false
    @State private var showJournal = false
    @State private var showLearn = false
    @State private var titleOpacity = 0.0
    @State private var subtitleOpacity = 0.0
    @State private var buttonOpacity = 0.0
    @State private var symbolOpacity = 0.0
    @State private var setupHintOpacity = 0.0
    @State private var hasCheckedFirstLaunch = false

    private func t(_ key: String, _ params: [String: String] = [:]) -> String {
        i18n.t(key, params: params)
    }

    var body: some View {
        ZStack {
            // Subtle gradient background (purple top → gold bottom)
            LinearGradient(
                colors: [
                    theme.colors.accent.opacity(0.04),
                    theme.colors.background,
                    theme.colors.gold.opacity(0.03)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Particle background
            StarfieldView(theme: theme)

            VStack(spacing: 0) {
                // Top bar: language selector + journal
                HStack {
                    HStack(spacing: 8) {
                        ForEach(["en", "zh", "fr", "es"], id: \.self) { locale in
                            Button(localeLabel(locale)) {
                                i18n.setLocale(locale)
                            }
                            .font(.system(size: 11, weight: i18n.locale == locale ? .semibold : .regular))
                            .foregroundColor(i18n.locale == locale ? theme.colors.accent : theme.colors.muted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                i18n.locale == locale
                                    ? theme.colors.accent.opacity(0.08)
                                    : Color.clear
                            )
                            .cornerRadius(12)
                        }
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button {
                            showLearn = true
                        } label: {
                            Image(systemName: "graduationcap")
                                .font(.system(size: 13))
                                .foregroundColor(theme.colors.muted)
                                .frame(width: 32, height: 32)
                                .background(theme.colors.surface.opacity(0.6))
                                .cornerRadius(16)
                        }

                        Button {
                            showJournal = true
                        } label: {
                            Image(systemName: "book")
                                .font(.system(size: 14))
                                .foregroundColor(theme.colors.muted)
                                .frame(width: 32, height: 32)
                                .background(theme.colors.surface.opacity(0.6))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()

                // Title area
                VStack(spacing: 20) {
                    Text("Tarot Mystica")
                        .font(.system(size: 42, weight: .light, design: .serif))
                        .foregroundColor(theme.colors.foreground)
                        .opacity(titleOpacity)

                    Text(t("hero.subtitle"))
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(subtitleOpacity)

                    // Decorative symbol
                    Text("✦")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.gold.opacity(0.5))
                        .opacity(symbolOpacity)
                        .padding(.top, 4)
                }

                Spacer()

                // Begin button or setup hint
                if llm.config.configured {
                    Button {
                        Haptic.primaryAction()
                        withAnimation(.easeInOut(duration: 0.4)) {
                            state.phase = .question
                        }
                    } label: {
                        Text(t("hero.startButton"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [theme.colors.accent, theme.colors.accent.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: theme.colors.accent.opacity(0.3), radius: 16, y: 6)
                    }
                    .opacity(buttonOpacity)
                } else {
                    // First launch: setup hint
                    VStack(spacing: 16) {
                        Button {
                            Haptic.primaryAction()
                            showSettings = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                Text(t("hero.setupAI"))
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [theme.colors.accent, theme.colors.accent.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: theme.colors.accent.opacity(0.3), radius: 16, y: 6)
                        }

                        Text(t("hero.setupHint"))
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.muted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .opacity(setupHintOpacity)
                }

                Spacer().frame(height: 48)

                // AI Status
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        aiStatusIndicator
                        Button {
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 14))
                                .foregroundColor(theme.colors.muted)
                                .frame(width: 32, height: 32)
                                .background(theme.colors.surface.opacity(0.6))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) { titleOpacity = 1.0 }
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) { subtitleOpacity = 1.0 }
            withAnimation(.easeOut(duration: 0.6).delay(0.7)) { symbolOpacity = 1.0 }
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) { buttonOpacity = 1.0 }

            // First launch: show setup hint after splash finishes
            if !llm.config.configured && !hasCheckedFirstLaunch {
                hasCheckedFirstLaunch = true
                withAnimation(.easeOut(duration: 0.6).delay(1.0)) { setupHintOpacity = 1.0 }
            }
        }
        .onChange(of: state.splashFinished) { _, finished in
            if finished && !llm.config.configured {
                // Delay slightly so the hero page is visible first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    if !llm.config.configured {
                        showSettings = true
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
                .environment(llm)
                .environment(i18n)
                .environment(theme)
        }
        .sheet(isPresented: $showJournal) {
            JournalView()
                .environment(i18n)
                .environment(theme)
        }
        .sheet(isPresented: $showLearn) {
            LearnView()
                .environment(i18n)
                .environment(theme)
        }
    }

    @ViewBuilder
    private var aiStatusIndicator: some View {
        if llm.config.configured {
            HStack(spacing: 6) {
                Circle()
                    .fill(llm.isReady ? Color.green : (llm.mlxService.isLoading ? Color.orange : theme.colors.muted))
                    .frame(width: 6, height: 6)
                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.muted)
            }
        }

        // Local model download progress
        if case .downloading(let progress, let text) = llm.mlxService.state {
            VStack(spacing: 4) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 200)
                    .tint(theme.colors.accent)
                Text(text)
                    .font(.system(size: 10))
                    .foregroundColor(theme.colors.muted)
            }
        } else if case .loading = llm.mlxService.state {
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.6)
                Text("Loading model...")
                    .font(.system(size: 10))
                    .foregroundColor(theme.colors.muted)
            }
        }
    }

    private var statusText: String {
        if llm.isReady {
            return "✨ \(t("hero.aiReady"))"
        }
        return t("ai.notReady")
    }

    private func localeLabel(_ locale: String) -> String {
        switch locale {
        case "en": return "EN"
        case "zh": return "中文"
        case "fr": return "FR"
        case "es": return "ES"
        default: return locale.uppercased()
        }
    }
}

// MARK: - Starfield Background Animation

private struct StarfieldView: View {
    let theme: ThemeManager
    @State private var particles: [Star] = []
    @State private var timer: Timer?

    struct Star: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var targetOpacity: Double
        var rotation: Double       // current angle
        var rotationSpeed: Double  // degrees per tick
        var driftX: CGFloat        // slow horizontal drift
        var driftY: CGFloat        // slow vertical drift
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.04)) { _ in
            Canvas { context, size in
                for star in particles {
                    let cx = star.x * size.width
                    let cy = star.y * size.height

                    // Draw a 4-pointed star, rotated
                    let path = starPath(cx: cx, cy: cy, outerR: star.size, innerR: star.size * 0.28, rotation: star.rotation)

                    context.opacity = star.opacity
                    context.fill(path, with: .color(theme.colors.gold.opacity(0.7)))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            particles = (0..<35).map { _ in
                let targetOp = Double.random(in: 0.08...0.35)
                return Star(
                    x: CGFloat.random(in: 0...1),
                    y: CGFloat.random(in: 0...1),
                    size: CGFloat.random(in: 4...12),
                    opacity: targetOp,
                    targetOpacity: targetOp,
                    rotation: Double.random(in: 0...360),
                    rotationSpeed: Double.random(in: 0.15...0.6) * (Bool.random() ? 1 : -1),
                    driftX: CGFloat.random(in: -0.00015...0.00015),
                    driftY: CGFloat.random(in: -0.00015...0.00015)
                )
            }
            timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
                for i in particles.indices {
                    // Smooth continuous rotation
                    particles[i].rotation += particles[i].rotationSpeed

                    // Gentle drift
                    particles[i].x += particles[i].driftX
                    particles[i].y += particles[i].driftY

                    // Soft opacity breathing (lerp toward target, then pick new target)
                    let diff = particles[i].targetOpacity - particles[i].opacity
                    particles[i].opacity += diff * 0.03
                    if abs(diff) < 0.01 {
                        particles[i].targetOpacity = Double.random(in: 0.06...0.3)
                    }

                    // Wrap around
                    if particles[i].y < -0.03 {
                        particles[i].y = 1.03
                        particles[i].x = CGFloat.random(in: 0...1)
                    }
                    if particles[i].x < -0.03 { particles[i].x = 1.03 }
                    if particles[i].x > 1.03 { particles[i].x = -0.03 }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    /// 4-pointed star path with rotation
    private func starPath(cx: CGFloat, cy: CGFloat, outerR: CGFloat, innerR: CGFloat, rotation: Double) -> Path {
        var path = Path()
        let rotRad = rotation * .pi / 180
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4 - .pi / 2 + rotRad
            let r = i % 2 == 0 ? outerR : innerR
            let px = cx + CGFloat(cos(angle)) * r
            let py = cy + CGFloat(sin(angle)) * r
            if i == 0 { path.move(to: CGPoint(x: px, y: py)) }
            else { path.addLine(to: CGPoint(x: px, y: py)) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Settings Sheet

private struct SettingsSheet: View {
    @Environment(LLMService.self) private var llm
    @Environment(LocalizationManager.self) private var i18n
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var mode: AIConfig.Mode = .api
    @State private var selectedLocalModel: String = ""
    @State private var apiProvider = ""
    @State private var apiKey = ""
    @State private var apiModel = ""
    @State private var apiBaseUrl = ""
    @State private var interpretationStyle: AIConfig.InterpretationStyle = .standard

    private func t(_ key: String, _ params: [String: String] = [:]) -> String {
        i18n.t(key, params: params)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Mode toggle
                    modeSelector

                    if mode == .local {
                        localModelSection
                    } else {
                        apiSection
                    }

                    // Interpretation style (shared across modes)
                    interpretationStyleSection
                }
                .padding(20)
            }
            .background(theme.colors.background)
            .navigationTitle(t("hero.aiSettings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("hero.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if mode == .api {
                        Button(t("hero.confirmMode")) {
                            saveAPIConfig()
                            dismiss()
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .onAppear { loadState() }
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        VStack(spacing: 12) {
            Text(t("hero.chooseMode"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.foreground)

            HStack(spacing: 0) {
                modeButton(title: t("hero.localModel"), subtitle: nil, icon: "iphone", mode: .local)
                modeButton(title: t("hero.externalAPI"), subtitle: t("hero.advancedLabel"), icon: "cloud", mode: .api)
            }
            .background(theme.colors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.colors.border, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func modeButton(title: String, subtitle: String?, icon: String, mode: AIConfig.Mode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.mode = mode
            }
        } label: {
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                }
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 9))
                        .opacity(0.7)
                }
            }
            .foregroundColor(self.mode == mode ? .white : theme.colors.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                self.mode == mode
                    ? theme.colors.accent
                    : Color.clear
            )
            .cornerRadius(10)
            .padding(2)
        }
    }

    // MARK: - Local Model

    private var localModelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("hero.localModelDesc"))
                .font(.system(size: 12))
                .foregroundColor(theme.colors.muted)

            ForEach(llm.localModels, id: \.id) { model in
                localModelRow(model)
            }

            // Download progress
            if case .downloading(let progress, let text) = llm.mlxService.state {
                VStack(spacing: 6) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(theme.colors.accent)
                    Text(text)
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.muted)
                }
                .padding(.top, 4)
            } else if case .loading = llm.mlxService.state {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7)
                    Text("Loading model into memory...")
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.muted)
                }
            } else if case .error(let msg) = llm.mlxService.state {
                Text(msg)
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.8))
            }
        }
    }

    private func modelDescription(_ name: String) -> String {
        if name.contains("Gemma") && name.contains("2B") { return t("hero.modelDescGemma2B") }
        if name.contains("Qwen") && name.contains("1.5B") { return t("hero.modelDescQwen1_5B") }
        if name.contains("Qwen") && name.contains("3B") { return t("hero.modelDescQwen3B") }
        if name.contains("Phi") { return t("hero.modelDescPhi") }
        if name.contains("Llama") { return t("hero.modelDescLlama") }
        return ""
    }

    @ViewBuilder
    private func localModelRow(_ model: MLXService.LocalModel) -> some View {
        let isSelected = selectedLocalModel == model.id
        let isLoaded = llm.mlxService.loadedModelId == model.id && llm.mlxService.isReady

        Button {
            selectedLocalModel = model.id
            Task {
                await llm.loadLocalModel(model.id)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.colors.foreground)
                    HStack(spacing: 6) {
                        Text(model.size)
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.muted)
                        let desc = modelDescription(model.name)
                        if !desc.isEmpty {
                            Text("·")
                                .font(.system(size: 11))
                                .foregroundColor(theme.colors.muted.opacity(0.5))
                            Text(desc)
                                .font(.system(size: 10))
                                .foregroundColor(theme.colors.muted.opacity(0.7))
                        }
                    }
                }

                Spacer()

                if isLoaded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                } else if isSelected && llm.mlxService.isLoading {
                    ProgressView().scaleEffect(0.7)
                }
            }
            .padding(12)
            .background(
                isLoaded
                    ? theme.colors.accent.opacity(0.06)
                    : (isSelected ? theme.colors.surface : Color.clear)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isLoaded ? theme.colors.accent.opacity(0.3) : theme.colors.border,
                        lineWidth: 1
                    )
            )
        }
        .disabled(llm.mlxService.isLoading)
    }

    // MARK: - API

    private var apiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("hero.externalAPIDesc"))
                .font(.system(size: 12))
                .foregroundColor(theme.colors.muted)

            // Provider chips
            VStack(alignment: .leading, spacing: 6) {
                Text(t("hero.provider"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.colors.foreground)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(["openai", "deepseek", "anthropic", "google", "openrouter", "custom"], id: \.self) { p in
                            Text(p.capitalized)
                                .font(.system(size: 12))
                                .foregroundColor(apiProvider == p ? .white : theme.colors.muted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(apiProvider == p ? theme.colors.accent : theme.colors.surface)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(apiProvider == p ? Color.clear : theme.colors.border, lineWidth: 1)
                                )
                                .onTapGesture { apiProvider = p }
                        }
                    }
                }
            }

            // API Key
            VStack(alignment: .leading, spacing: 4) {
                Text("API Key")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.colors.foreground)
                SecureField("sk-...", text: $apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .font(.system(size: 14))
                    .padding(10)
                    .background(theme.colors.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.colors.border, lineWidth: 1)
                    )
            }

            if apiProvider == "custom" {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t("hero.baseUrl"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.colors.foreground)
                    TextField("https://...", text: $apiBaseUrl)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.system(size: 14))
                        .padding(10)
                        .background(theme.colors.surface)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.colors.border, lineWidth: 1)
                        )
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(t("hero.model"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.colors.foreground)
                TextField("gpt-4.1", text: $apiModel)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(theme.colors.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.colors.border, lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Interpretation Style

    private var interpretationStyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("settings.interpretationStyle"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.foreground)

            Text(t("settings.interpretationStyleDesc"))
                .font(.system(size: 12))
                .foregroundColor(theme.colors.muted)

            VStack(spacing: 8) {
                ForEach(AIConfig.InterpretationStyle.allCases, id: \.self) { style in
                    let isSelected = interpretationStyle == style
                    Button {
                        Haptic.selection()
                        interpretationStyle = style
                        llm.updateConfig { c in
                            c.interpretationStyle = style
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text(styleIcon(style))
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t("settings.style.\(style.rawValue).label"))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(theme.colors.foreground)
                                Text(t("settings.style.\(style.rawValue).desc"))
                                    .font(.system(size: 10))
                                    .foregroundColor(theme.colors.muted)
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.colors.accent)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(12)
                        .background(
                            isSelected ? theme.colors.accent.opacity(0.06) : Color.clear
                        )
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    isSelected ? theme.colors.accent.opacity(0.3) : theme.colors.border,
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
    }

    private func styleIcon(_ style: AIConfig.InterpretationStyle) -> String {
        switch style {
        case .concise: return "⚡"
        case .standard: return "✦"
        case .poetic: return "🌙"
        case .analytical: return "📊"
        }
    }

    // MARK: - Actions

    private func loadState() {
        mode = llm.config.mode
        selectedLocalModel = llm.config.localModel
        apiProvider = llm.config.apiProvider
        apiKey = llm.config.apiKey
        apiModel = llm.config.apiModel
        apiBaseUrl = llm.config.apiBaseUrl
        interpretationStyle = llm.config.interpretationStyle
    }

    private func saveAPIConfig() {
        llm.updateConfig { c in
            c.mode = .api
            c.apiProvider = apiProvider
            c.apiKey = apiKey
            c.apiModel = apiModel
            c.apiBaseUrl = apiBaseUrl
            c.configured = !apiKey.isEmpty
        }
    }
}
