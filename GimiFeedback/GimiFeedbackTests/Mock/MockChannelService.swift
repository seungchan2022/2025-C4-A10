import Foundation
@testable import GimiFeedback

final class MockChannelService: ChannelRepository {
  
  // 우리가 마음대로 데이터를 설정하기 위한 변수
  var fetchResult: [FeedbackChannel] = []
  var fetchError: Error? // 에러 상황을 테스트하고 싶을 때 사용할 변수
  
  // 뷰모델이 진짜로 우리가 테스트하려는 함수를 호출했는지 세어보기 위한 카운트(행동 검증을 위한 장치)
  var fetchCallCount: Int = .zero
  
  // 실제 Repository가 헤야 할일을 흉내냄
  func fetch(userId: String) async throws -> [FeedbackChannel] {
    fetchCallCount += 1
    
    // 에러를 설정했으면 에러를 던짐 (실패 테스트용)
    if let error = fetchError {
      throw error
    }
    
    // 미리 준비한 데이터를 리턴 (성공 테스트용)
    return fetchResult
  }
  
  func create(_ channel: FeedbackChannel) async throws { }
  
  func get(id: String) async throws -> FeedbackChannel? { return .none }
  
  func delete(_ channel: FeedbackChannel) async throws { }
  
  func update(_ channel: FeedbackChannel) async throws { }
  
}
