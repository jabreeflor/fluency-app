import SwiftUI

// MARK: - Multiple Choice

struct MultipleChoiceView: View {
    let exercise: ExerciseContent
    @ObservedObject var session: LessonSession
    @State private var selectedOption: String?

    var body: some View {
        VStack(spacing: 16) {
            Text(exercise.question)
                .font(.system(.title3, design: .default, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(FluencyTheme.textPrimary)
                .padding(.bottom, 8)

            if exercise.audioFile != nil {
                Button {
                    session.playAudio(file: exercise.audioFile ?? "")
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title)
                        .foregroundStyle(FluencyTheme.primary)
                        .padding(16)
                        .background(FluencyTheme.primary.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            ForEach(exercise.options ?? [], id: \.self) { option in
                OptionCard(
                    text: option,
                    state: optionState(for: option),
                    action: {
                        guard case .active = session.sessionState else { return }
                        selectedOption = option
                        session.userAnswer = option
                    }
                )
            }
        }
    }

    private func optionState(for option: String) -> OptionCardState {
        guard let selected = selectedOption,
              case .showingFeedback = session.sessionState else {
            return selectedOption == option ? .selected : .normal
        }
        if option == exercise.correctAnswer { return .correct }
        if option == selected { return .incorrect }
        return .normal
    }
}

enum OptionCardState { case normal, selected, correct, incorrect }

struct OptionCard: View {
    let text: String
    let state: OptionCardState
    let action: () -> Void

    private var bgColor: Color {
        switch state {
        case .normal: return FluencyTheme.cardBg
        case .selected: return FluencyTheme.primary.opacity(0.08)
        case .correct: return FluencyTheme.success.opacity(0.15)
        case .incorrect: return FluencyTheme.error.opacity(0.15)
        }
    }

    private var borderColor: Color {
        switch state {
        case .normal: return FluencyTheme.border
        case .selected: return FluencyTheme.primary
        case .correct: return FluencyTheme.success
        case .incorrect: return FluencyTheme.error
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(FluencyTheme.bodyFont)
                    .foregroundStyle(FluencyTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                switch state {
                case .correct:
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(FluencyTheme.success)
                case .incorrect:
                    Image(systemName: "xmark.circle.fill").foregroundStyle(FluencyTheme.error)
                case .selected:
                    Image(systemName: "circle.inset.filled").foregroundStyle(FluencyTheme.primary)
                case .normal:
                    EmptyView()
                }
            }
            .padding(FluencyTheme.cardPadding)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius).stroke(borderColor, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .animation(FluencyTheme.springSnappy, value: state)
    }
}

// MARK: - Fill in the Blank / Translation

struct FillBlankView: View {
    let exercise: ExerciseContent
    @ObservedObject var session: LessonSession
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text(exercise.question)
                .font(.system(.title3, design: .default, weight: .semibold))
                .multilineTextAlignment(.center)
                // Highlight Spanish parts in primary blue
                .foregroundStyle(FluencyTheme.textPrimary)

            TextField("Type your answer...", text: $session.userAnswer)
                .font(.title3)
                .padding(FluencyTheme.cardPadding)
                .background(FluencyTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius)
                        .stroke(isFocused ? FluencyTheme.primary : FluencyTheme.border, lineWidth: 2)
                )
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - Word Bank

struct WordBankView: View {
    let exercise: ExerciseContent
    @ObservedObject var session: LessonSession
    @State private var selectedWords: [String] = []
    @State private var availableWords: [String] = []

    var body: some View {
        VStack(spacing: 24) {
            Text(exercise.question)
                .font(.system(.title3, design: .default, weight: .semibold))
                .multilineTextAlignment(.center)

            // Answer area
            ZStack {
                RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius)
                    .stroke(selectedWords.isEmpty ? FluencyTheme.border : FluencyTheme.primary, lineWidth: 2)
                    .frame(minHeight: 60)

                if selectedWords.isEmpty {
                    Text("Tap words below to build your answer")
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(selectedWords, id: \.self) { word in
                            WordBubble(word: word, isSelected: true) {
                                selectedWords.removeAll { $0 == word }
                                availableWords.append(word)
                                syncAnswer()
                            }
                        }
                    }
                    .padding(8)
                }
            }
            .padding(.horizontal)

            // Word bank
            FlowLayout(spacing: 8) {
                ForEach(availableWords, id: \.self) { word in
                    WordBubble(word: word, isSelected: false) {
                        availableWords.removeAll { $0 == word }
                        selectedWords.append(word)
                        syncAnswer()
                    }
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            availableWords = (exercise.options ?? []).shuffled()
        }
    }

    private func syncAnswer() {
        session.userAnswer = selectedWords.joined(separator: " ")
    }
}

// MARK: - Listening

struct ListeningView: View {
    let exercise: ExerciseContent
    @ObservedObject var session: LessonSession
    @State private var hasPlayed = false

    var body: some View {
        VStack(spacing: 24) {
            Text("What do you hear?")
                .font(.system(.title3, design: .default, weight: .semibold))

            Button {
                hasPlayed = true
                session.playAudio(file: exercise.audioFile ?? "")
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: hasPlayed ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(FluencyTheme.primary)
                    Text(hasPlayed ? "Tap to replay" : "Tap to listen")
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                }
                .padding(32)
                .background(FluencyTheme.primary.opacity(0.1))
                .clipShape(Circle())
            }

            TextField("Type what you heard...", text: $session.userAnswer)
                .font(.title3)
                .padding(FluencyTheme.cardPadding)
                .background(FluencyTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius).stroke(FluencyTheme.border, lineWidth: 2))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }
}

// MARK: - Speaking

struct SpeakingView: View {
    let exercise: ExerciseContent
    @ObservedObject var session: LessonSession
    @ObservedObject private var speechService = SpeechService.shared
    @State private var showTypeInstead = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Say this in Spanish:")
                .font(.system(.title3, design: .default, weight: .semibold))

            Text("\"\(exercise.question)\"")
                .font(.title.italic())
                .foregroundStyle(FluencyTheme.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if showTypeInstead {
                TextField("Type the Spanish phrase...", text: $session.userAnswer)
                    .font(.title3)
                    .padding(FluencyTheme.cardPadding)
                    .background(FluencyTheme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius).stroke(FluencyTheme.border, lineWidth: 2))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } else {
                // Mic button
                Button {
                    if speechService.isListening {
                        session.userAnswer = session.stopSpeaking()
                    } else {
                        session.startSpeaking()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(speechService.isListening ? FluencyTheme.error : FluencyTheme.primary)
                            .frame(width: 88, height: 88)
                            .shadow(color: (speechService.isListening ? FluencyTheme.error : FluencyTheme.primary).opacity(0.35),
                                    radius: speechService.isListening ? 20 : 8)
                            .scaleEffect(speechService.isListening ? 1.12 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                                .delay(speechService.isListening ? 0 : 100), value: speechService.isListening)

                        Image(systemName: speechService.isListening ? "mic.fill" : "mic")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                }

                Text(speechService.isListening ? "Listening… tap to stop" : "Tap the mic to speak")
                    .font(FluencyTheme.captionFont)
                    .foregroundStyle(FluencyTheme.textSecondary)

                if !speechService.transcription.isEmpty {
                    Text("Heard: \"\(speechService.transcription)\"")
                        .font(FluencyTheme.bodyFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if let error = speechService.errorMessage {
                    Text(error)
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.error)
                }

                Button("Type instead") {
                    speechService.stopListening()
                    showTypeInstead = true
                }
                .font(FluencyTheme.captionFont)
                .foregroundStyle(FluencyTheme.textSecondary)
            }
        }
        .onDisappear { speechService.stopListening() }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.size.height }.max() ?? 0 }.reduce(0, +)
            + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.size.height }.max() ?? 0
            for item in row {
                item.view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[(view: LayoutSubview, size: CGSize)]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[(view: LayoutSubview, size: CGSize)]] = [[]]
        var rowWidth: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if rowWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append((view: view, size: size))
            rowWidth += size.width + spacing
        }
        return rows
    }
}
