//
//  ViewModel.swift
//  Inneal
//
//  Created by Brad Root on 3/24/24.
//

import Foundation
import SwiftData
import SwiftUI

extension ChatView {
    struct ViewModelResponse {
        let text: String
        let character: Character?
        let response: String?
        let request: String?
    }

    @MainActor
    class ViewModel {
        var chat: Chat
        var modelContext: ModelContext
        var userSettings: UserSettings
        let hordeAPI: HordeAPI = .init()

        var baseHordeRequest: HordeRequest = defaultHordeRequest
        var baseHordeParams: HordeRequestParams = defaultHordeParams

        init(for chat: Chat, modelContext: ModelContext, userSettings: UserSettings) {
            self.chat = chat
            self.modelContext = modelContext
            self.userSettings = userSettings

            if let settingData = chat.hordeSettings,
               let decodedSettings = try? JSONDecoder().decode(HordeRequest.self, from: settingData)
            {
                Log.debug("Loaded settings from chat...")
                baseHordeRequest = decodedSettings
                baseHordeParams = decodedSettings.params
            }
        }

        func getNewResponseToChat(statusMessage: Binding<String>, contentAlternate: Bool = false, character: Character? = nil) async -> ViewModelResponse {
            Log.debug("Got request for new response to chat...")
            return await getResponseFromHorde(statusMessage: statusMessage, contentAlternate, character)
        }

        fileprivate func getResponseFromHorde(statusMessage: Binding<String>, _ contentAlternate: Bool = false, _ fromCharacter: Character? = nil) async -> ViewModelResponse {
            Log.debug("Requesting new chat from the horde...")
            var currentRequestUUID: UUID?

            var hordeApiKey = "0000000000"

            var userName = chat.userName ?? userSettings.defaultUserName
            var userCharacter = chat.userCharacter
            if userCharacter == nil, chat.userName == nil, let uChar = userSettings.userCharacter {
                userCharacter = uChar
                userName = uChar.name
            }
            if userCharacter != nil {
                Log.debug("User character in use, name: \(userName)")
            }

            do {
                let descriptor = FetchDescriptor<APIConfiguration>(predicate: #Predicate { $0.serviceName == "horde" })
                let configurations = try modelContext.fetch(descriptor)
                guard let currentConfiguration = configurations.first, let config = currentConfiguration.configurationData else { throw MyError.runtimeError("No configs?") }
                hordeApiKey = String(data: config, encoding: .utf8)!
            } catch {
                let baseHordeConfig = APIConfiguration(serviceName: "horde", configurationData: "0000000000".data(using: .utf8)!)
                modelContext.insert(baseHordeConfig)
            }

            var history: [ChatMessage] = []
            do {
                let id = chat.uuid
                let descriptor = FetchDescriptor<ChatMessage>(predicate: #Predicate { $0.chatUUID == id }, sortBy: [SortDescriptor(\.dateCreated, order: .reverse)])
                history = try modelContext.fetch(descriptor)
            } catch {
                Log.error("Unable to fetch message history")
            }

            guard let characters = chat.characters, !characters.isEmpty, var character = chat.characters?.first else {
                return ViewModelResponse(text: "No characters found in chat.", character: nil, response: nil, request: nil)
            }

            if contentAlternate, let lastMessage = history.first, let toon = lastMessage.character {
                Log.debug("Alternate requested, setting character to last message character: \(toon.name).")
                character = toon
            } else if let fromChar = fromCharacter {
                Log.debug("Requested message for a specific character \(fromChar.name)")
                character = fromChar
            } else {
                Log.debug("Trying to determine next character in chat...")
                mainLoop: for message in history {
                    if message.fromUser, let randomToon = characters.randomElement() {
                        for currentWord in extractAllWords(from: message.content) {
                            for chatCharacter in characters {
                                if extractAllWords(from: chatCharacter.name).contains(currentWord) {
                                    Log.debug("Found mention, setting toon: \(chatCharacter.name)")
                                    character = chatCharacter
                                    break mainLoop
                                }
                            }
                        }
                        Log.debug("Setting random toon: \(randomToon.name)")
                        character = randomToon
                        break mainLoop
                    } else {
                        Log.debug("Setting toon that isn't \(message.character?.name ?? "Unknown Character")")
                        let filteredToons = characters.filter { $0 != message.character }
                        for currentWord in extractAllWords(from: message.content) {
                            for chatCharacter in filteredToons {
                                if extractAllWords(from: chatCharacter.name).contains(currentWord) {
                                    Log.debug("Found mention, setting toon: \(chatCharacter.name)")
                                    character = chatCharacter
                                    break mainLoop
                                }
                            }
                        }
                        if let randomToon = filteredToons.randomElement() {
                            Log.debug("Setting random toon: \(randomToon.name)")
                            character = randomToon
                        }
                        break mainLoop
                    }
                }
            }

            var maxContentLength = baseHordeParams.maxContentLength
            var maxLength = baseHordeParams.maxLength
            var eligibleModels = baseHordeRequest.models
            var eligibleWorkers = baseHordeRequest.workers

            var permanentPrompt = "## {{char}}\n- You're \"{{char}}\" in this never-ending roleplay with \"{{user}}\".\n### Input:\n"
            if chat.unwrappedCharacters.count > 1 {
                let presentCharacters = chat.unwrappedCharacters.filter { $0 != character }
                let characterNames = presentCharacters.compactMap({"\"\($0.name)\""}).joined(separator: ", ")
                permanentPrompt = "## {{char}}\n- You're \"{{char}}\" in this never-ending roleplay with \"{{user}}\", \(characterNames).\n### Input:\n"
            }
            permanentPrompt += character.characterDescription.isEmpty ? "" : "\(character.characterDescription)\n"
            permanentPrompt += character.personality.isEmpty ? "" : "{{char}}'s personality: \(character.personality)\n"
            permanentPrompt += character.scenario.isEmpty ? "" : "Scenario: \(character.scenario)\n"

            if let userCharacter, userCharacter != character {
                permanentPrompt += "\n"
                permanentPrompt += "\(userCharacter.characterDescription.swapPlaceholders(userName: character.name, charName: userCharacter.name, userSettings: userSettings))\n"
            }

            permanentPrompt += "### Response:\n(OOC) Understood. I will take this info into account for the roleplay. (end OOC)"

            let permanentTokens = countTokens(permanentPrompt)
            Log.debug("Permanent tokens: \(permanentTokens)")

            if chat.autoModeEnabled {
                var desiredContextWindow = 2048
                switch chat.preferredContextWindow {
                case .any:
                    desiredContextWindow = 2048
                case .medium:
                    desiredContextWindow = 4096
                case .large:
                    desiredContextWindow = 8192
                }

                if permanentTokens >= 1536, desiredContextWindow == 2048 {
                    Log.debug("Permanent tokens over 1536, setting desired context window to 4096.")
                    desiredContextWindow = 4096
                }

                Log.debug("Fetching workers...")
                let hordeWorkers = await hordeAPI.getWorkers()
                Log.debug("Found \(hordeWorkers.count) workers.")

                Log.debug("Fetching models...")
                let hordeModels = await hordeAPI.getModels()
                Log.debug("Found \(hordeModels.count) models.")

                var modelStubs: [String] = ["pygmalion-6", "pygmalion-v8", "pygmalion-2", "hermes", "airoboros", "chrono", "llama", "wizard", "mantis", "myth", "xwin", "spicyboros", "mlewd", "mxlewd", "mistral", "maid", "mixtral", "estopia", "fighter", "fimbul"]
                var modelStubsBackups: [String] = ["pygmalion", "janeway", "nerys", "erebus", "nerybus", "opt", "vicuna", "manticore", "alpaca"]

                if chat.preferredModel != .any {
                    modelStubsBackups.append(contentsOf: modelStubs)
                    switch chat.preferredModel {
                    case .any:
                        break
                    case .fim:
                        modelStubs = ["fimbul"]
                    case .estopia:
                        modelStubs = ["estopia"]
                    case .fighter:
                        modelStubs = ["fighter"]
                    case .llama2:
                        modelStubs = ["llama2"]
                    case .mistral:
                        modelStubs = ["mistral", "mixtral"]
                    case .pygma:
                        modelStubs = ["mistral", "mixtral"]
                    }
                }

                var selectedModels = hordeModels.filter { model in
                    modelStubs.contains { modelStub in
                        model.name.lowercased().contains(modelStub)
                    }
                }

                if selectedModels.isEmpty {
                    Log.debug("Model list is empty, using backup model stub list.")
                    selectedModels = hordeModels.filter { model in
                        modelStubsBackups.contains { modelStub in
                            model.name.lowercased().contains(modelStub)
                        }
                    }
                }
                if selectedModels.isEmpty {
                    Log.debug("Model list still empty, weird.")
                    if let firstModel = hordeModels.first {
                        selectedModels = [firstModel]
                    }
                }

                var selectedWorkers = hordeWorkers.filter { worker in
                    selectedModels.contains { model in
                        model.name == worker.models.first && !worker.maintenanceMode && worker.maxContextLength >= desiredContextWindow
                    }
                }

                if chat.preferredResponseSize == .large, !selectedWorkers.isEmpty {
                    Log.debug("Large response size preference invoked, checking for response size...")
                    let largeWorkers = hordeWorkers.filter { worker in
                        selectedModels.contains { model in
                            model.name == worker.models.first && !worker.maintenanceMode && worker.maxContextLength >= desiredContextWindow && worker.maxLength >= 512
                        }
                    }
                    if !largeWorkers.isEmpty {
                        Log.debug("Large response size workers found, overwriting found workers with new workers.")
                        selectedWorkers = largeWorkers
                    }
                }

                if selectedWorkers.isEmpty {
                    Log.debug("Worker list is empty, no workers matched desired context window.")
                    selectedWorkers = hordeWorkers.filter { worker in
                        selectedModels.contains { model in
                            model.name == worker.models.first && !worker.maintenanceMode
                        }
                    }
                }

                var mCL = 0
                var mL = 0
                for worker in selectedWorkers {
                    if mCL == 0 {
                        mCL = worker.maxContextLength
                    } else {
                        mCL = min(worker.maxContextLength, mCL)
                    }

                    if mL == 0 {
                        mL = worker.maxLength
                    } else {
                        mL = min(worker.maxLength, mL)
                    }
                }
                maxLength = mL
                maxContentLength = mCL

                Log.debug("Determined \(maxContentLength) \\ \(maxLength)")

                if chat.preferredResponseSize == .small, maxLength > 120 {
                    Log.debug("Small response size preference invoked, reducing response size.")
                    maxLength = 120
                }

                eligibleModels = selectedModels.map(\.name)
                eligibleWorkers = selectedWorkers.map(\.id)

                Log.debug("Found \(selectedModels.count) eligible models and \(selectedWorkers.count) eligible workers.")
            }

            var prompt = permanentPrompt
            prompt += "\n\n"
            var currentTokenCount = permanentTokens
            Log.debug("Permanent prompt applied, \(currentTokenCount) tokens used, \(maxContentLength - currentTokenCount) remain.")

            var messageHistory = ""
            if contentAlternate {
                _ = history.removeFirst()
            }
            for m in history {
                let message = "\(m.fromUser ? "{{user}}" : "{{char}}"): \(m.content)\n".swapPlaceholders(userName: userName, charName: m.character?.name, userSettings: userSettings)
                let tokens = countTokens(message)
                if (maxContentLength - (currentTokenCount + tokens)) >= 0 {
                    messageHistory = "\(message)\(messageHistory)"
                    currentTokenCount += tokens
                }
            }
            Log.debug("Built message history, \(currentTokenCount) tokens used, \(maxContentLength - currentTokenCount) remain.")

            var exampleMessageHistory = ""
            var exampleChats = character.exampleMessage.components(separatedBy: "<START>")
            exampleChats = exampleChats.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            for m in exampleChats {
                let tokens = countTokens(m)
                if (maxContentLength - (currentTokenCount + tokens)) >= 0 {
                    exampleMessageHistory.append("### New Roleplay:\n\(m)\n")
                    currentTokenCount += tokens
                }
            }
            Log.debug("Built message examples, \(currentTokenCount) tokens used, \(maxContentLength - currentTokenCount) remain.")

            if !exampleMessageHistory.isEmpty {
                prompt.append(exampleMessageHistory)
                prompt.append("\n")
            }

            prompt.append("### New Roleplay:\n")
            prompt.append(messageHistory)
            prompt.append("{{char}}:")

            prompt = prompt.swapPlaceholders(userName: userName, charName: character.name, userSettings: userSettings)

            Log.debug("Total token count: \(countTokens(prompt))")

            var stopSequence = ["{{user}}:", "\n{{user}} "]
            for character in chat.characters ?? [] {
                stopSequence.append("\n\(character.name): ")
            }

            let params = HordeRequestParams(
                n: baseHordeParams.n,
                maxContentLength: maxContentLength,
                maxLength: maxLength,
                repPen: baseHordeParams.repPen,
                temperature: baseHordeParams.temperature,
                topP: baseHordeParams.topP,
                topK: baseHordeParams.topK,
                topA: baseHordeParams.topA,
                typical: baseHordeParams.typical,
                tfs: baseHordeParams.tfs,
                repPenRange: baseHordeParams.repPenRange,
                repPenSlope: baseHordeParams.repPenSlope,
                samplerOrder: baseHordeParams.samplerOrder,
                useDefaultBadwordsids: baseHordeParams.useDefaultBadwordsids,
                stopSequence: stopSequence.map { $0.swapPlaceholders(userName: userName, charName: character.name, userSettings: userSettings) },
                minP: baseHordeParams.minP,
                dynatempRange: baseHordeParams.dynatempRange,
                dynatempExponent: baseHordeParams.dynatempExponent,
                smoothingFactor: baseHordeParams.smoothingFactor
            )

            let hordeRequest = HordeRequest(
                prompt: prompt,
                params: params,
                models: eligibleModels,
                workers: eligibleWorkers
            )
            Log.debug("\(hordeRequest)")
            let requestString = hordeRequest.toJSONString()

            Log.debug("Sending message to API...")
            do {
                let requestResponse = try await hordeAPI.submitRequest(apiKey: hordeApiKey, request: hordeRequest)
                currentRequestUUID = requestResponse.id
            } catch APIError.requestTimedOut {
                return ViewModelResponse(text: "(OOC: Unable to communicate with the AI Horde. Is your internet working? Maybe the horde is down.)", character: character, response: nil, request: requestString)
            } catch let APIError.invalidResponse(statusCode, content) {
                Log.error("Received \(statusCode) from AI Horde API. \(content)")
                if statusCode == 429 {
                    return ViewModelResponse(text: "(OOC: The Horde is experiencing heavy loads from anonymous users and had to reject your request. Wait a moment, then swipe to get a new response. Consider setting up an API key in Settings, signup is still anonymous.)", character: character, response: nil, request: requestString)
                }
            } catch {
                Log.error("\(error)")
            }

            if let requestUUID = currentRequestUUID {
                var failures = 0
                while true {
                    do {
                        let requestResponse = try await hordeAPI.checkRequest(apiKey: hordeApiKey, requestUUID: requestUUID)
                        Log.debug("\(requestResponse)")
                        if requestResponse.done {
                            if let generation = requestResponse.generations.first {
                                statusMessage.wrappedValue = "Text from \(generation.model)"
                                var result = endTrimToSentence(input: generation.text, includeNewline: true)
                                result = result.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                                result = trimToFirstNewline(text: result, characterName: character.name, userName: userName, multilineReplies: chat.allowMultilineReplies)
                                // result = ensureEvenAsterisks(result)
                                // result = ensureEvenQuotes(result)
                                result = replaceMultipleNewlines(in: result)
                                result = result.replacingOccurrences(of: userName, with: "{{user}}").replacingOccurrences(of: character.name, with: "{{char}}").trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                                return ViewModelResponse(text: result, character: character, response: requestResponse.toJSONString(), request: requestString)
                            }
                            break
                        } else {
                            if !requestResponse.isPossible {
                                return ViewModelResponse(text: "(OOC: Request can not be completed as sent. Please check that your current chat settings match a worker's capabilities.)", character: character, response: requestResponse.toJSONString(), request: requestString)
                            } else if requestResponse.processing == 0 {
                                if requestResponse.queuePosition > 0 {
                                    statusMessage.wrappedValue = "Waiting... (#\(requestResponse.queuePosition) in queue)"
                                } else {
                                    statusMessage.wrappedValue = "Waiting..."
                                }
                            } else {
                                statusMessage.wrappedValue = "\(character.name) is typing..."
                            }
                            try await Task.sleep(nanoseconds: 3_000_000_000)
                        }
                    } catch APIError.requestTimedOut {
                        return ViewModelResponse(text: "(OOC: Unable to communicate with the AI Horde. Is your internet working? Maybe the horde is down.)", character: character, response: nil, request: requestString)

                    } catch let APIError.invalidResponse(statusCode, content) {
                        Log.error("Received \(statusCode) from AI Horde API. \(content)")
                        failures += 1
                        if failures > 5 {
                            Log.error("Reached maximum failures, breaking polling loop.")
                            break
                        }
                    } catch {
                        Log.error("Uknown error occurred when polling horde? \(error)")
                    }
                }
            }
            return ViewModelResponse(text: "(OOC: Did not receive a successful generation from the AI Horde. Please retry.)", character: character, response: nil, request: requestString)
        }

//
//        fileprivate func getResponseFromOpenAI() async -> String {
//            let openAIKey = ""
//            let url = URL(string: "https://api.openai.com/v1/chat/completions")!
//
//            var request = URLRequest(url: url)
//            request.httpMethod = "POST"
//            request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//            let systemPrompt = GPTMessage(role: "system", content: "The following is an interesting chat message log between Bradley and you, a chatbot named Inneal.")
//
//            var currentMessages: [GPTMessage] = [systemPrompt]
//            do {
//                let id = chat.uuid
//                let descriptor = FetchDescriptor<ChatMessage>(predicate: #Predicate { $0.chatUUID == id }, sortBy: [SortDescriptor(\.dateCreated)])
//                let history = try modelContext.fetch(descriptor)
//                history.forEach { m in
//                    currentMessages.append(GPTMessage(role: m.fromUser ? "user" : "assistant", content: m.content))
//                }
//            } catch {
//                Log.debug("Unable to grab mesage history")
//            }
//            Log.debug(currentMessages)
//            let parameters = GPTParameters(model: "gpt-3.5-turbo", messages: currentMessages)
//
//            Log.debug("Encoding paremeters")
//
//            let encodedParameters = try? JSONEncoder().encode(parameters)
//            request.httpBody = encodedParameters
//
//            Log.debug("Sending message to API...")
//            statusMessage = "Sending message..."
//            do {
//                let (data, response) = try await URLSession.shared.data(for: request)
//                if let response = response as? HTTPURLResponse {
//                    if response.statusCode == 200 {
//                        Log.debug("Got successful response from API")
//                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                           let choices = json["choices"] as? [[String: Any]],
//                           let choice = choices.first,
//                           let message = choice["message"] as? [String: Any],
//                           let text = message["content"] as? String
//                        {
//                            Log.debug("Returning response...")
//                            statusMessage = "Send a message"
//                            return text
//                        }
//                    }
//                }
//            } catch {
//                Log.debug(error)
//            }
//            return "An error has occurred..."
//        }

        func ensureEvenAsterisks(_ input: String) -> String {
            // Count the asterisks in the string
            let asteriskCount = input.filter { $0 == "*" }.count

            // If the count is odd, append an asterisk to make it even
            if asteriskCount % 2 != 0 {
                return input + "*"
            }

            // Return the original string if the asterisk count is already even
            return input
        }

        func ensureEvenQuotes(_ input: String) -> String {
            // Count the asterisks in the string
            let asteriskCount = input.filter { $0 == "\"" }.count

            // If the count is odd, append an asterisk to make it even
            if asteriskCount % 2 != 0 {
                return input + "\""
            }

            // Return the original string if the asterisk count is already even
            return input
        }

        func endTrimToSentence(input: String, includeNewline: Bool = false) -> String {
            var last = -1
            let enders: [String.Element] = [".", "!", "?", "*", "\"", ")", "}", "`", "]", ";", "…"]

            for ender in enders {
                if let index = input.lastIndex(of: ender) {
                    last = max(last, input.distance(from: input.startIndex, to: index))
                }
            }

            if includeNewline {
                if let index = input.lastIndex(of: "\n") {
                    last = max(last, input.distance(from: input.startIndex, to: index))
                }
            }

            if last > 0 {
                let endIndex = input.index(input.startIndex, offsetBy: last + 1)
                let trimmedString = String(input[input.startIndex ..< endIndex])
                return trimmedString.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            return input.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        func trimToFirstNewline(text: String, characterName: String, userName: String, multilineReplies: Bool = true) -> String {
            var gentxt = text

            let oppomatch = characterName + ": "
            let oppomatchwithNL = "\n" + characterName + ": "
            if let rangeOfOppoMatch = gentxt.range(of: oppomatch), rangeOfOppoMatch.lowerBound == gentxt.startIndex {
                gentxt.removeSubrange(rangeOfOppoMatch)
            }

            let foundMyNameRange = gentxt.range(of: userName + ":")
            let foundMyName2Range = gentxt.range(of: "\n" + userName + " ")
            let foundAltYouName = try! NSRegularExpression(pattern: "\nYou [A-Z\"\'*] ", options: .caseInsensitive)
            let foundAltYouNameRes = foundAltYouName.matches(in: gentxt, options: [], range: NSRange(gentxt.startIndex..., in: gentxt))
            var splitresponse = [String]()

            func pruneMultiliners(inputArr: [String]) -> [String] {
                if !multilineReplies {
                    let mlCheck = inputArr[0]
                    let moreOpponents = try! NSRegularExpression(pattern: "\n(?!" + userName + ").+?: ", options: .caseInsensitive)
                    let foundMoreOpponent = moreOpponents.matches(in: mlCheck, options: [], range: NSRange(mlCheck.startIndex..., in: mlCheck))
                    if !foundMoreOpponent.isEmpty {
                        return mlCheck.components(separatedBy: "\n")
                    }
                }
                return inputArr
            }

            if foundMyNameRange != nil {
                splitresponse = gentxt.components(separatedBy: userName + ":")
                splitresponse = pruneMultiliners(inputArr: splitresponse)
            } else if foundMyName2Range != nil, userName != "You" || !foundAltYouNameRes.isEmpty {
                splitresponse = gentxt.components(separatedBy: "\n" + userName + " ")
                splitresponse = pruneMultiliners(inputArr: splitresponse)
            } else if let rangeOfOppoMatchWithNL = gentxt.range(of: oppomatchwithNL), !rangeOfOppoMatchWithNL.isEmpty {
                splitresponse = gentxt.components(separatedBy: "\n" + characterName + ": ")
                splitresponse = pruneMultiliners(inputArr: splitresponse)
            } else {
                if multilineReplies {
                    splitresponse.append(gentxt)
                } else {
                    if gentxt.hasPrefix("\""), let endQuoteIndex = gentxt.range(of: "\"", options: [], range: gentxt.index(after: gentxt.startIndex) ..< gentxt.endIndex) {
                        splitresponse.append(String(gentxt[..<endQuoteIndex.upperBound]))
                    } else {
                        splitresponse = gentxt.components(separatedBy: "\n")
                    }
                }
            }

            var startPart = splitresponse[0]
            if startPart.hasSuffix("\n") {
                startPart = String(startPart.dropLast())
            }
            return startPart
        }

        func replaceMultipleNewlines(in text: String) -> String {
            let pattern = "\n{3,}" // Regex pattern to match three or more newline characters
            let replacement = "\n\n" // Replacement string
            let newText = text.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
            return newText
        }

        func countTokens(_ string: String) -> Int {
            Int(ceil(Double(string.count) / 3.5))
        }
    }
}
