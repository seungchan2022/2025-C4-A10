import Foundation

final class GeminiService: GeminiRepository {
  func generate(inputText: String) async throws -> String {
    return try await GeminiManager.shared.generate(inputText: inputText)
  }
}
