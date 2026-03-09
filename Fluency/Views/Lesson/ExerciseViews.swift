import SwiftUI

// MARK: - Multiple Choice

struct MultipleChoiceView: View {
    let exercise: ExerciseContent
    @ObservedObject var session: LessonSession
    @State private var selectedOption: String?

    var body: some View {
        VStack(spacing: 16) {
            // Question
            Text(exercise.question)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            // Audio button (if available)
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

            // Options
            ForEach(exercise.options ?? [], id: \.self) { option in
                OptionButton(
                    text: option,
                    state: optionState(for: option),
                    action: {
                        guard case .active = session.sessionState else { return }
                        selectedOption = option
                        session.submitAnswer(option)
                    }
                )
            }
        }
    }

    private func optionState(for option: String) -> OptionButtonState {
        guard let selected = selectedOption else { return .normal }
        if option == exercise.correctAnswer { return .correct }
        if option == selected { return .incorrect }
        return .normal
    }
}

enum OptionButtonState { case normal, correct, incorrect }

struct OptionButton: View {
    let text: String
    let state: OptionButtonState
    let action: () -> Void

    var bgColor: Color {
        switch state {
        case .normal: return FluencyTheme.cardBg
        case .correct: return FluencyTheme.correctGreen
        case .incorrect: return FluencyTheme.wrongRed
        }
    }

    var borderColor: Color {
        switch state {
        case .normal: return FluencyTheme.border
        case .correct: return FluencyTheme.correctBorder
        case .incorrect: return FluencyTheme.wrongBorder
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
                if state == .correct {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(FluencyTheme.correctBorder)
                } else if state == .incorrect {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(FluencyTheme.wrongBorder)
                }
            }
            .padding(FluencyTheme.cardPadding)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .animation(.easeOut(duration: 0.15), value: state)
    }
}

// MARK: - Fill in the Blank / Translation

struct FillBlankView: View {
    let exercise: ExerciseContent
    @ObservedObject var session: LessonSession
    @State private var textInput: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text(exercise.question)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            // Text input
            TextField("Type your answer...", text: $textInput)
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
                .onSubmit {
                    guard !textInput.isEmpty else { return }
                    session.submitAnswer(textInput)
                }

            // Submit button
            Button("Check Answer") {
                guard !textInput.isEmpty else { return }
                session.submitAnswer(textInput)
            }
            .buttonStyle(FluencyButtonStyle(isDisabled: textInput.isEmpty))
            .disabled(textInput.isEmpty)
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
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            // Answer area
            ZStack {
                RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius)
                    .stroke(FluencyTheme.border, lineWidth: 2)
                    .frame(minHeight: 60)

                if selectedWords.isEmpty {
                    Text("Tap words below to build your answer")
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(selectedWords, id: \.self) { word in
                            WordChip(word: word, isSelected: true) {
                                selectedWords.removeAll { $0 == word }
                                availableWords.append(word)
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
                    WordChip(word: word, isSelected: false) {
                        availableWords.removeAll { $0 == word }
                        selectedWords.append(word)
                    }
                }
            }
            .padding(.horizontal)

            // Submit
            Button("Check Answer") {
                let answer = selectedWords.joined(separator: ",")
                session.submitAnswer(answer)
            }
            .buttonStyle(FluencyButtonStyle(isDisabled: selectedWords.isEmpty))
            .disabled(selectedWords.isEmpty)
        }
        .onAppear {
            availableWords = (exercise.options ?? []).shuffled()
        }
    }
}

struct WordChip: View {
    let word: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(word)
                .font(FluencyTheme.bodyFont)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? FluencyTheme.primary.opacity(0.15) : FluencyTheme.cardBg)
                .foregroundStyle(isSelected ? FluencyTheme.primary : FluencyTheme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? FluencyTheme.primary : FluencyTheme.border, lineWidth: 2)
                )
        }
    }
}

// MARK: - Listening

struct ListeningView: View {
    let exercise: ExerciseContent
    @ObservedObject var session: LessonSession
    @State private var textInput: String = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("What do you hear?")
                .font(.title2.weight(.semibold))

            // Play button
            Button {
                session.playAudio(file: exercise.audioFile ?? "")
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(FluencyTheme.primary)
                    Text("Tap to listen")
                        .font(FluencyTheme.captionFont)
                        .foregroundStyle(FluencyTheme.textSecondary)
                }
                .padding(32)
                .background(FluencyTheme.primary.opacity(0.1))
                .clipShape(Circle())
            }

            TextField("Type what you heard...", text: $textInput)
                .font(.title3)
                .padding(FluencyTheme.cardPadding)
                .background(FluencyTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: FluencyTheme.cornerRadius).stroke(FluencyTheme.border, lineWidth: 2))
                .autocorrectionDisabled()

            Button("Check Answer") {
                session.submitAnswer(textInput)
            }
            .buttonStyle(FluencyButtonStyle(isDisabled: textInput.isEmpty))
            .disabled(textInput.isEmpty)
        }
    }
}

// MARK: - Speaking

struct SpeakingView: View {
    let exercise: ExerciseContent
    @ObservedObject var session: LessonSession

    var body: some View {
        VStack(spacing: 24) {
            Text("Say this in Spanish:")
                .font(.title2.weight(.semibold))

            Text("\"\(exercise.question)\"")
                .font(.title.italic())
                .foregroundStyle(FluencyTheme.primary)
                .multilineTextAlignment(.center)

            // Mic button
            Button {
                session.isListening ? session.isListening = false : (session.isListening = true)
            } label: {
                ZStack {
                    Circle()
                        .fill(session.isListening ? FluencyTheme.accent : FluencyTheme.primary)
                        .frame(width: 80, height: 80)
                        .scaleEffect(session.isListening ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: session.isListening)
                    Image(systemName: session.isListening ? "mic.fill" : "mic")
                        .font(.title)
                        .foregroundStyle(.white)
                }
            }

            if !session.recognizedSpeech.isEmpty {
                Text("Heard: \"\(session.recognizedSpeech)\"")
                    .font(FluencyTheme.bodyFont)
                    .foregroundStyle(FluencyTheme.textSecondary)

                Button("Submit") {
                    session.submitAnswer(session.recognizedSpeech)
                }
                .buttonStyle(FluencyButtonStyle())
            }

            // Skip option
            Button("Skip (type instead)") {
                session.submitAnswer("__skip__")
            }
            .font(FluencyTheme.captionFont)
            .foregroundStyle(FluencyTheme.textSecondary)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.size.height }.max() ?? 0 }.reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
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
