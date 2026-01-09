import Foundation
@testable import GimiFeedback

final class MockFeedbackService: FeedbackRepository {
  
  // [채널 ID: [피드백 목록]]
  var fetchResult: [String: [Feedback]] = [:]
  var fetchError: Error?
  
  var fetchCallCount: Int = .zero

  func fetch(channelId: String) async throws -> [Feedback] {
    fetchCallCount += 1
    
    if let error = fetchError {
      throw error
    }
    
    // 요청 받은 channelId에 맞는 피드백이 있으면 주고, 없으면 빈 배열 반환
    return fetchResult[channelId] ?? []
  }

  
  func create(_ feedback: Feedback) async throws -> Feedback {
    return feedback
  }
  
  func get(id: String) async throws -> Feedback? { return .none }
  
  func delete(_ feedback: Feedback) async throws { }
  
  func update(_ feedback: Feedback) async throws { }
  
  
}
