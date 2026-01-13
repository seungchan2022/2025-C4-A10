import Foundation

protocol GeminiRepository {
  func generate(inputText: String) async throws -> String 
}
