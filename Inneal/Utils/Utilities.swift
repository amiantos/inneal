//
//  Utilities.swift
//  Inneal
//
//  Created by Brad Root on 4/4/24.
//

import Combine
import Foundation
import SwiftUI

// MARK: - PNG Processing

// Define the PNG signature
let pngSignature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]

// Define chunk types
let textChunkTypes: [String] = ["tEXt", "zTXt", "iTXt"]

func downloadPNGData(from urlString: String) async throws -> Data {
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }

    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}

// Function to read a PNG file and extract text chunks
func readPNGTextChunks(from fileData: Data) async -> (TavernCharacterData?, Data?) {
//    let fileData = try! await downloadPNGData(from: urlString)

    // Check PNG signature
    if fileData.starts(with: pngSignature) {
        var cursor = pngSignature.count

        // Iterate over chunks
        while cursor < fileData.count {
            // Read chunk length
            let lengthData = fileData.subdata(in: cursor ..< (cursor + 4))
            let length = UInt32(bigEndian: lengthData.withUnsafeBytes { $0.load(as: UInt32.self) })
            cursor += 4

            // Read chunk type
            let typeData = fileData.subdata(in: cursor ..< (cursor + 4))
            let type = String(bytes: typeData, encoding: .ascii) ?? ""
            cursor += 4

            // Check if it's a text chunk
            if textChunkTypes.contains(type) {
                // Read chunk data
                let chunkData = fileData.subdata(in: cursor ..< (cursor + Int(length)))
                if let text = String(data: chunkData, encoding: .utf8) {
                    if text.hasPrefix("chara") {
                        let base64string = String(text.dropFirst(6))
                        Log.debug(base64string)
                        if let data = Data(base64Encoded: base64string) {
                            do {
                                let pngData = try JSONDecoder().decode(TavernData.self, from: data)
                                return (pngData.data, fileData)
                            } catch {
                                do {
                                    let pngData = try JSONDecoder().decode(TavernSimple.self, from: data)
                                    return (TavernCharacterData(name: pngData.name, description: pngData.description, personality: pngData.personality, firstMes: pngData.firstMes, avatar: pngData.avatar, mesExample: pngData.mesExample, scenario: pngData.scenario, creatorNotes: "", systemPrompt: "", postHistoryInstructions: "", alternateGreetings: [], tags: [], creator: "", characterVersion: ""), fileData)
                                } catch {
                                    Log.debug("\(error)")
                                }
                            }
                        }
                    }
                }
                cursor += Int(length)
            } else {
                // Skip chunk data
                cursor += Int(length)
            }

            // Skip CRC
            cursor += 4

            // Check if we've reached the IEND chunk
            if type == "IEND" {
                break
            }
        }
    } else {
        Log.debug("File is not a valid PNG.")
    }

    return (nil, nil)
}

// MARK: - Stuff?

public extension Binding {

    static func convert<TInt, TFloat>(from intBinding: Binding<TInt>) -> Binding<TFloat>
    where TInt:   BinaryInteger,
          TFloat: BinaryFloatingPoint{

        Binding<TFloat> (
            get: { TFloat(intBinding.wrappedValue) },
            set: { intBinding.wrappedValue = TInt($0) }
        )
    }

    static func convert<TFloat, TInt>(from floatBinding: Binding<TFloat>) -> Binding<TInt>
    where TFloat: BinaryFloatingPoint,
          TInt:   BinaryInteger {

        Binding<TInt> (
            get: { TInt(floatBinding.wrappedValue) },
            set: { floatBinding.wrappedValue = TFloat($0) }
        )
    }
}

extension String {
    func swapPlaceholders(userName: String?, charName: String?) -> String {
        return self.replacingOccurrences(of: "{{user}}", with: userName ?? Preferences.standard.defaultName)
            .replacingOccurrences(of: "{{char}}", with: charName ?? "Uknown Character")
            .replacingOccurrences(of: "{{User}}", with: userName ?? Preferences.standard.defaultName)
            .replacingOccurrences(of: "{{Char}}", with: charName ?? "Uknown Character")
    }
}

func loadJSONFromFile(fileName: String) -> [String: Any]? {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
        return nil
    }

    do {
        let data = try Data(contentsOf: url)
        if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            return jsonObject
        } else {
            Log.error("Data is not a dictionary")
        }
    } catch {
        Log.error("Error reading JSON file: \(error)")
    }
    return nil
}

extension View {
    func readIntrinsicContentSize(to size: Binding<CGSize>) -> some View {
        background(GeometryReader { proxy in
            Color.clear.preference(
                key: IntrinsicContentSizePreferenceKey.self,
                value: proxy.size
            )
        })
        .onPreferenceChange(IntrinsicContentSizePreferenceKey.self) {
            size.wrappedValue = $0
        }
    }
}

struct IntrinsicContentSizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension Encodable {
    func toJSONString() -> String {
        let jsonData = try! JSONEncoder().encode(self)
        return String(data: jsonData, encoding: .utf8)!
    }
}

extension Data {
    func printJson() -> String? {
        do {
            let json = try JSONSerialization.jsonObject(with: self, options: [])
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                return nil
            }
            return jsonString
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil
        }
    }
}

extension View {

  var keyboardPublisher: AnyPublisher<Bool, Never> {
    Publishers
      .Merge(
        NotificationCenter
          .default
          .publisher(for: UIResponder.keyboardWillShowNotification)
          .map { _ in true },
        NotificationCenter
          .default
          .publisher(for: UIResponder.keyboardWillHideNotification)
          .map { _ in false })
      .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
      .eraseToAnyPublisher()
  }
}
