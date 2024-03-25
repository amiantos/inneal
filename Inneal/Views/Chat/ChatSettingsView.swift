//
//  ChatSettingsView.swift
//  Inneal
//
//  Created by Brad Root on 4/7/24.
//

import SwiftData
import SwiftUI

enum SettingsMode: String, CaseIterable, Identifiable {
    case auth = "Auth"
    case basic = "Basic"
    case advance = "Advanced"
    var id: Self { self }
}


struct ChatSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @State var chat: Chat
    @State var viewModel: ChatSettingsView.ViewModel = .init()
    @State var showingContextPicker: Bool = false
    @State var showingGeneratePicker: Bool = false
    @State var service: Services = .horde

    @State var hordeRequest: HordeRequest
    @State var hordeParams: HordeRequestParams

    @State var currentHordeConfigObject: APIConfiguration?
    @State var showingAPIKeyDeleteAlert = false

    @Environment(\.modelContext) var modelContext

    @State var settingsMode: SettingsMode = .basic
    @State var customUserName: String = ""

    var body: some View {
        NavigationStack {
            Picker("Settings Mode", selection: $settingsMode) {
                ForEach(SettingsMode.allCases) { mode in
                    Text(mode.rawValue)
                }
            }.pickerStyle(.segmented).padding([.leading, .trailing])
            Form {
                if settingsMode == .basic {
                    Section(header: Text("Your Name"), footer: Text("Your name in this specific chat.")) {
                        TextField(Preferences.standard.defaultName, text: $customUserName)
                            .onChange(of: customUserName) {
                                if customUserName.isEmpty {
                                    chat.userName = nil
                                } else {
                                    chat.userName = customUserName
                                }
                            }
                    }
                }
                if service == .horde {
                    if settingsMode == .basic {
                        Section(header: Text("Model Settings"), footer: chat.autoModeEnabled ? Text("Automatic mode automatically chooses models from the Horde for you, and automatically configures some settings to match currently available workers.\n\nSet a preferred model and preferred context window to guide automatic mode toward a model and context window you prefer, but if they are not available, auto mode will fall back to other models and contexts to get a response.\n\nPreferred Response Size can have considerable impact on generation times. Only change it if you prefer much longer character responses, and consider turning on 'Allow Multiline Replies' in advanced settings.") : nil) {
                            Toggle("Automatic Mode", isOn: $chat.autoModeEnabled)
                            if chat.autoModeEnabled {
                                Picker("Preferred Model", selection: $chat.preferredModel) {
                                    ForEach(PreferredModel.allCases) { model in
                                        Text(model.rawValue)
                                    }
                                }
                                Picker("Preferred Context", selection: $chat.preferredContextWindow) {
                                    ForEach(PreferredContextWindow.allCases) { context in
                                        Text(context.rawValue)
                                    }
                                }
                                Picker("Preferred Response Size", selection: $chat.preferredResponseSize) {
                                    ForEach(PreferredResponseSize.allCases) { size in
                                        Text(size.rawValue)
                                    }
                                }
                            }
                        }
                        if !chat.autoModeEnabled {
                            Section(footer: Text("Maximum number of context tokens sent to the AI. Must exceed amount to generate. Older models stop at 2048, new models can go to 4096 and beyond.")) {
                                Button {
                                    showingContextPicker.toggle()
                                } label: {
                                    LabeledContent("Context Tokens", value: "\(hordeParams.maxContentLength)")
                                }
                                .alert("Enter max context tokens", isPresented: $showingContextPicker) {
                                    TextField("Enter maximum context tokens", value: $hordeParams.maxContentLength, formatter: NumberFormatter())
                                        .keyboardType(.numberPad)
                                    Button("OK") { }
                                }
                            }

                            Section(footer: Text("Number of tokens for the AI to generate. Larger numbers take longer to generate.")) {
                                Button {
                                    showingGeneratePicker.toggle()
                                } label: {
                                    LabeledContent("Amount to Generate", value: "\(hordeParams.maxLength)")
                                }
                                .alert("Enter tokens to generate", isPresented: $showingGeneratePicker) {
                                    TextField("Enter tokens to generate", value: $hordeParams.maxLength, formatter: NumberFormatter())
                                        .keyboardType(.numberPad)
                                    Button("OK") { }
                                }
                                Slider(value: .convert(from: $hordeParams.maxLength), in: 16 ... 512, step: 16)
                            }

                            Section(header: Text("Select Model")) {
                                Picker("Select Model By...", selection: $viewModel.selectionType) {
                                    ForEach(["Models", "Workers"], id: \.self) { style in
                                        Text(style)
                                    }
                                }.pickerStyle(.segmented)
                                if viewModel.selectionType == "Models" {
                                    List(viewModel.hordeModels, id: \.name) { model in
                                        Button {
                                            hordeRequest.workers.removeAll()
                                            if hordeRequest.models.contains(model.name) {
                                                hordeRequest.models.removeAll { $0 == model.name }
                                            } else {
                                                hordeRequest.models.append(model.name)
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: hordeRequest.models.contains(model.name) ? "checkmark.circle.fill" : "circle")
                                                    .foregroundStyle(.accent)
                                                    .padding(.trailing, 5)
                                                VStack {
                                                    HStack {
                                                        Text(model.name.replacingOccurrences(of: "aphrodite/", with: "").replacingOccurrences(of: "koboldcpp/", with: "")).lineLimit(1).truncationMode(.head).minimumScaleFactor(0.1)
                                                        Spacer()
                                                    }
                                                    Spacer()
                                                    HStack {
                                                        Text("Threads: \(model.count)")
                                                        Text("Speed: \(String(format: "%.2f", model.performance))")
                                                        Text("Queue: \(String(format: "%.0f", model.queued))")
                                                        Spacer()
                                                    }.font(.caption).foregroundStyle(.secondary)
                                                }
                                                Text(model.name.contains("aphrodite") ? "A" : model.name.contains("koboldcpp") ? "K" : "?")
                                                    .bold()
                                                    .minimumScaleFactor(0.5)
                                                    .padding(5)
                                                    .frame(width: 22, height: 22)
                                                    .foregroundColor(.primary)
                                                    .background(.tertiary)
                                                    .clipShape(Circle())
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .frame(height: 40)
                                    }
                                } else {
                                    List(viewModel.hordeWorkers, id: \.name) { worker in
                                        Button {
                                            if hordeRequest.workers.contains(worker.id) {
                                                hordeRequest.workers.removeAll { $0 == worker.id }
                                                var newSet = Set<String>()
                                                for hordeWorker in viewModel.hordeWorkers where hordeRequest.workers.contains(hordeWorker.id) {
                                                    if let modelName = hordeWorker.models.first {
                                                        newSet.insert(modelName)
                                                    }
                                                }
                                                hordeRequest.models = Array(newSet)
                                            } else {
                                                if hordeRequest.workers.isEmpty {
                                                    hordeRequest.models.removeAll()
                                                }
                                                hordeRequest.workers.append(worker.id)
                                                if let model = worker.models.first, !hordeRequest.models.contains(model) {
                                                    hordeRequest.models.append(model)
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: hordeRequest.workers.contains(worker.id) ? "checkmark.circle.fill" : "circle")
                                                    .foregroundStyle(.accent)
                                                    .padding(.trailing, 5)
                                                VStack(alignment: .leading) {
                                                    Text(worker.name).lineLimit(1).truncationMode(.head).minimumScaleFactor(0.1)
                                                    VStack(alignment: .leading) {
                                                        HStack {
                                                            if let modelName = worker.models.first {
                                                                Text(modelName.replacingOccurrences(of: "aphrodite/", with: "").replacingOccurrences(of: "koboldcpp/", with: ""))
                                                                    .truncationMode(.tail)
                                                            }
                                                        }
                                                        HStack {
                                                            Text("Context: \(worker.maxContextLength)")
                                                            Text("Length: \(worker.maxLength)")
                                                        }
                                                        HStack {
                                                            Text("Threads: \(worker.threads)")
                                                            Text(worker.performance)
                                                        }

                                                    }.font(.caption).foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                                if worker.maintenanceMode {
                                                    Image(systemName: "exclamationmark.triangle.fill")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .padding(5)
                                                        .frame(width: 22, height: 22)
                                                        .foregroundColor(.red)
                                                        .background(.tertiary)
                                                        .clipShape(Circle())
                                                }
                                                VStack {
                                                    if worker.trusted {
                                                        Image(systemName: "heart.fill")
                                                            .resizable()
                                                            .scaledToFill()
                                                            .padding(5)
                                                            .frame(width: 22, height: 22)
                                                            .foregroundColor(.pink)
                                                            .background(.tertiary)
                                                            .clipShape(Circle())
                                                    }
                                                    if let modelName = worker.models.first {
                                                        Text(modelName.contains("aphrodite") ? "A" : modelName.contains("koboldcpp") ? "K" : "?")
                                                            .bold()
                                                            .minimumScaleFactor(0.5)
                                                            .padding(5)
                                                            .frame(width: 22, height: 22)
                                                            .foregroundColor(.primary)
                                                            .background(.tertiary)
                                                            .clipShape(Circle())
                                                    }
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .frame(height: 75)
                                    }
                                }
                            }
                        }
                    }
                    if settingsMode == .advance {
                        Section(footer: Text("Whether to allow multiple lines in AI responses. Disable this if the AI starts generating rubbish.")) {
                            Toggle("Multiline Replies", isOn: $chat.allowMultilineReplies)
                        }
                        Section(footer: Text("Randomness of sampling. High values can increase creativity but may make text less sensible. Lower values will make text more predictable but can become repetitious.")) {
                            LabeledContent("Temperature", value: String(format: "%.1f", hordeParams.temperature))
                            Slider(value: $hordeParams.temperature, in: 0.1 ... 2, step: 0.1)
                        }
                        .onChange(of: hordeParams.temperature) {
                            hordeParams.temperature = Float(String(format: "%.1f", hordeParams.temperature))!
                        }

                        Section(footer: Text("Used to discard unlikely text in the sampling process. Lower values will make text more predictable but can become repetitious. Set to 1 to deactivate it.")) {
                            LabeledContent("Top P Sampling", value: String(format: "%.2f", hordeParams.topP))
                            Slider(value: $hordeParams.topP, in: 0.0 ... 1.0, step: 0.01)
                        }
                        .onChange(of: hordeParams.topP) {
                            hordeParams.topP = Float(String(format: "%.2f", hordeParams.topP))!
                        }

                        Section(footer: Text("Used to penalize words that were already generated or belong to the context (Going over 1.2 breaks 6B models).")) {
                            LabeledContent("Repetition Penalty", value: String(format: "%.2f", hordeParams.repPen))
                            Slider(value: $hordeParams.repPen, in: 1.0 ... 3.0, step: 0.01)
                        }
                        .onChange(of: hordeParams.repPen) {
                            hordeParams.repPen = Float(String(format: "%.2f", hordeParams.repPen))!
                        }
                    }
                    if settingsMode == .auth {
                        Section(header: Text("AI Horde API Key")) {
                            SecureField("Enter horde API key here", text: $viewModel.apiKey, onCommit: {
                                viewModel.currentUserName = nil
                                viewModel.onAppear()
                            })
                            .onSubmit {
                                currentHordeConfigObject?.configurationData = viewModel.apiKey.data(using: .utf8)!
                            }
                            .submitLabel(.done)
                            Button("Remove API Key") {
                                showingAPIKeyDeleteAlert = true
                            }
                            .disabled(viewModel.apiKey == "0000000000")
                            .alert("Delete API Key?", isPresented: $showingAPIKeyDeleteAlert) {
                                Button("OK", role: .destructive) {
                                    currentHordeConfigObject?.configurationData = "0000000000".data(using: .utf8)!
                                    viewModel.apiKey = "0000000000"
                                    viewModel.currentKudos = nil
                                    viewModel.currentUserName = nil
                                    viewModel.onAppear()
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("This is not recoverable, and applies to the encrypted cloud storage of your API key in Inneal, so be sure you have stored your API key somewhere else safe!")
                            }
                        }

                        Section(header: Text("AI Horde User Info"), footer: Text("Kudos is spent on generations and determines your order in the request queue, so the more kudos you have, the faster you get respones.\n\nAnonymous accounts do not have kudos and are effectively at the back of the line.\n\nYou can get more kudos by hosting your own horde workers, either for image generation or text generation. Visit the AI Horde website for more information.")) {
                            if viewModel.currentUserName != nil {
                                LabeledContent("Username", value: viewModel.currentUserName ?? "")
                                LabeledContent("Kudos", value: viewModel.currentKudos ?? "0")
                            } else {
                                ProgressView()
                                ProgressView()
                            }
                        }.onAppear {
                            if currentHordeConfigObject == nil {
                                do {
                                    let descriptor = FetchDescriptor<APIConfiguration>(predicate: #Predicate { $0.serviceName == "horde" })
                                    let configurations = try modelContext.fetch(descriptor)
                                    if configurations.isEmpty {
                                        Log.debug("Configs empty, creating")
                                        let baseHordeConfig = APIConfiguration(serviceName: "horde", configurationData: "0000000000".data(using: .utf8)!)
                                        modelContext.insert(baseHordeConfig)
                                        currentHordeConfigObject = baseHordeConfig
                                        viewModel.currentKudos = nil
                                        viewModel.currentUserName = nil
                                    } else if let hordeConfig = configurations.first, let configData = hordeConfig.configurationData, let keyString = String(data: configData, encoding: .utf8) {
                                        Log.debug("Found config, loading in")
                                        viewModel.apiKey = keyString
                                        currentHordeConfigObject = hordeConfig
                                        viewModel.currentKudos = nil
                                        viewModel.currentUserName = nil
                                    }
                                    viewModel.onAppear()
                                } catch {
                                    fatalError("Unable to find or create AI Horde config")
                                }
                            }
                        }
                        Link("Visit AIHorde.net", destination: URL(string: "https://aihorde.net")!)
                    }
                }

                if service != .horde {
                    Text("Coming soon!")
                }
            }
            .navigationTitle("Chat Settings")
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
//                    Menu {
//                        Picker("Chat API", selection: $service) {
//                            ForEach(Services.allCases) { mode in
//                                Text(mode.rawValue)
//                            }
//                        }
//                    } label: {
//                        Text(service.rawValue)
//                    }
                    Text("AI Horde")
                }

            }
            #if os(iOS)
            .scrollDismissesKeyboard(.immediately)
            #endif
            .onAppear(perform: {
                customUserName = chat.userName ?? ""
                Task {
                    await viewModel.populateModels()
                }
            })
        }
    }
}

extension ChatSettingsView {
    @Observable
    class ViewModel {
        var selectionType: String = "Models"
        var setValuesByWorker: Bool = true
        var hordeModels: [HordeModel] = []
        var hordeWorkers: [HordeWorker] = []
        let hordeAPI: HordeAPI = HordeAPI()
        var currentUserName: String?
        var currentKudos: String?
        var currentTrusted: Bool = false
        var apiKey: String = "0000000000"

        func populateModels() async {
            hordeModels = await hordeAPI.getModels()
            hordeWorkers = await hordeAPI.getWorkers()
        }

        func loadHordeUserData() async {
            if apiKey == "0000000000" {
                currentUserName = "Anonymous"
                currentKudos = "∞"
                return
            }

            if let userInfo = await hordeAPI.getUserInfo(apiKey: apiKey) {
                currentUserName = userInfo.username
                currentKudos = userInfo.kudos.formatted()
            } else {
                currentUserName = "Invalid API Key?"
                currentKudos = "404"
            }
        }

        func onAppear() {
            if currentUserName == nil || currentKudos == nil {
                Task {
                    await loadHordeUserData()
                }
            }
        }
    }
}

#Preview {
    struct Preview: View {
        @State var hordeRequest = defaultHordeRequest
        @State var hordeParams = defaultHordeParams
        @State var chat = Chat(name: "", characters: [])

        var body: some View {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: Chat.self, configurations: config)
            let character = Character(
                name: "Bradley Root",
                characterDescription: "Bradley is a software engineer",
                personality: "",
                firstMessage: "Hi! I'm Bradley!",
                exampleMessage: "",
                scenario: "",
                creatorNotes: "",
                systemPrompt: "",
                postHistoryInstructions: "",
                alternateGreetings: [],
                tags: [],
                creator: "Brad Root",
                characterVersion: "main",
                chubId: "",
                avatar: UIImage(named: "brad-real")!.pngData()!
            )
            container.mainContext.insert(character)
            chat = Chat(name: "Chat Name", characters: [character])
            container.mainContext.insert(chat)
            for i in 1 ..< 10 {
                let message = ChatMessage(content: "Lorem ipsum dolor sit amet. {{user}}? {{char}}? {{User}}? {{Char}}? consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", fromUser: i % 2 == 0 ? true : false, chat: chat, character: character)
                container.mainContext.insert(message)
            }
            try? container.mainContext.save()

            return ChatSettingsView(chat: chat, hordeRequest: hordeRequest, hordeParams: hordeParams).modelContainer(container)
        }
    }

    return Preview()
}
