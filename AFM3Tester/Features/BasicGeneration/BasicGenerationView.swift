import FoundationModels
import SwiftUI

@MainActor
@Observable
final class BasicGenerationViewModel {
    var prompt = SampleContent.defaultPrompts.first ?? ""
    var instructions = "You are a concise, helpful assistant."
    var temperature: Double = 0.7
    var useDeterministicSeed = false
    var deterministicSeed: UInt64 = 42
    var useStreaming = false
    var output = ""
    var streamOutput = ""
    var isRunning = false
    var lastMetrics: LatencyMetrics?
    var lastError: String?
    var sessionCreationSeconds: Double?
    private var runTask: Task<Void, Never>?
    private var session: LanguageModelSession?

    let defaultPrompts = SampleContent.defaultPrompts

    func clearSession(service: FoundationModelService) async {
        cancel()
        let created = await service.makeSession(instructions: instructions.isEmpty ? nil : instructions)
        session = created.session
        sessionCreationSeconds = created.creationTimeSeconds
        output = ""
        streamOutput = ""
        lastError = nil
        lastMetrics = nil
    }

    func cancel() {
        runTask?.cancel()
        runTask = nil
        isRunning = false
    }

    func run(service: FoundationModelService, store: DiagnosticStore) {
        cancel()
        isRunning = true
        runTask = Task {
            defer { isRunning = false }
            do {
                let created = await service.makeSession(instructions: instructions.isEmpty ? nil : instructions)
                session = created.session
                sessionCreationSeconds = created.creationTimeSeconds
                let options = generationOptions()

                if useStreaming {
                    streamOutput = ""
                    let result = try await service.streamRespond(
                        session: created.session,
                        prompt: prompt,
                        options: options,
                        onPartial: { [weak self] partial in
                            Task { @MainActor in
                                self?.streamOutput = partial
                            }
                        },
                        testName: "Basic Generation (Streaming)"
                    )
                    output = result.content
                    lastMetrics = LatencyMetrics(
                        sessionCreationSeconds: created.creationTimeSeconds,
                        timeToFirstTokenSeconds: result.metrics.timeToFirstTokenSeconds,
                        totalGenerationSeconds: result.metrics.totalGenerationSeconds,
                        charactersPerSecond: result.metrics.charactersPerSecond,
                        inputCharacterCount: result.metrics.inputCharacterCount,
                        outputCharacterCount: result.metrics.outputCharacterCount
                    )
                } else {
                    let result = try await service.respond(
                        session: created.session,
                        prompt: prompt,
                        options: options,
                        testName: "Basic Generation"
                    )
                    output = result.content
                    lastMetrics = LatencyMetrics(
                        sessionCreationSeconds: created.creationTimeSeconds,
                        timeToFirstTokenSeconds: result.metrics.timeToFirstTokenSeconds,
                        totalGenerationSeconds: result.metrics.totalGenerationSeconds,
                        charactersPerSecond: result.metrics.charactersPerSecond,
                        inputCharacterCount: result.metrics.inputCharacterCount,
                        outputCharacterCount: result.metrics.outputCharacterCount
                    )
                }
                lastError = nil
                store.recordTest(TestResult(
                    testName: "Basic Generation",
                    category: "generation",
                    outcome: .passed,
                    message: output.prefix(200).description,
                    latency: lastMetrics
                ))
            } catch is CancellationError {
                lastError = String(reflecting: CancellationError())
            } catch {
                let reflected = String(reflecting: error)
                lastError = reflected
                store.recordTest(TestResult(
                    testName: "Basic Generation",
                    category: "generation",
                    outcome: await service.isModelAvailable ? .failed : .unavailable,
                    message: error.localizedDescription,
                    rawError: reflected
                ))
            }
        }
    }

    private func generationOptions() -> GenerationOptions {
        var sampling: GenerationOptions.SamplingMode?
        if useDeterministicSeed {
            sampling = .random(top: 20, seed: deterministicSeed)
        }
        return GenerationOptions(
            sampling: sampling,
            temperature: temperature,
            maximumResponseTokens: nil
        )
    }
}

struct BasicGenerationView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var viewModel = BasicGenerationViewModel()
    @FocusState private var focusedField: Field?

    private enum Field { case prompt, instructions }

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                Text("Default Prompts")
                    .font(.headline)
                ForEach(Array(viewModel.defaultPrompts.enumerated()), id: \.offset) { index, text in
                    Button("Prompt \(Character(UnicodeScalar(65 + index)!))") {
                        viewModel.prompt = text
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }

                Text("Instructions")
                    .font(.headline)
                TextEditor(text: $viewModel.instructions)
                    .focused($focusedField, equals: .instructions)
                    .frame(minHeight: 60, maxHeight: 100)
                    .padding(8)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

                Text("Prompt")
                    .font(.headline)
                TextEditor(text: $viewModel.prompt)
                    .focused($focusedField, equals: .prompt)
                    .font(.body.monospaced())
                    .frame(minHeight: 120, maxHeight: 200)
                    .padding(8)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading) {
                    Text("Temperature: \(viewModel.temperature, specifier: "%.2f")")
                    Slider(value: $viewModel.temperature, in: 0...1)
                }

                Toggle("Deterministic sampling (fixed seed)", isOn: $viewModel.useDeterministicSeed)
                if viewModel.useDeterministicSeed {
                    Stepper("Seed: \(viewModel.deterministicSeed)", value: $viewModel.deterministicSeed, in: 1...9999)
                }

                Toggle("Streaming", isOn: $viewModel.useStreaming)

                HStack {
                    RunTestButton(title: "Run Model", isRunning: viewModel.isRunning) {
                        viewModel.run(service: service, store: store)
                    }
                    Button("Cancel") { viewModel.cancel() }
                        .buttonStyle(.bordered)
                        .disabled(!viewModel.isRunning)
                    Button("Clear Session") {
                        Task { await viewModel.clearSession(service: service) }
                    }
                    .buttonStyle(.bordered)
                }

                if let metrics = viewModel.lastMetrics {
                    GroupBox("Latency Metrics") {
                        LatencyMetricsView(metrics: metrics)
                    }
                }

                GroupBox("Output") {
                    Text(displayOutput)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let error = viewModel.lastError {
                    GroupBox("Error") {
                        Text(error)
                            .font(.caption.monospaced())
                            .foregroundStyle(.red)
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Basic Generation")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
    }

    private var displayOutput: String {
        if viewModel.isRunning && viewModel.useStreaming {
            return viewModel.streamOutput.isEmpty ? "Streaming…" : viewModel.streamOutput
        }
        return viewModel.output.isEmpty ? "Model output will appear here." : viewModel.output
    }
}
