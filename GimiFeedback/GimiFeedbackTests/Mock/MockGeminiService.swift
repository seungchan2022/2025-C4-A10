import Foundation
@testable import GimiFeedback

final class MockGeminiService: GeminiRepository {
  var result = ""
  var error: Error?
  
  var callCount: Int = .zero
  
  
  func generate(inputText: String) async throws -> String {
    callCount += 1
    
    if let error = error {
      throw error
    }
    return result
  }
}
