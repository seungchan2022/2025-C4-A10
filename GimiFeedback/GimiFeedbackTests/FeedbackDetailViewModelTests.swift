import XCTest

@testable import GimiFeedback

@MainActor
final class FeedbackDetailViewModelTests: XCTestCase {

  var sut: FeedbackDetailViewModel!
  var mockGeminiService: MockGeminiService!
  var mockFeedbackServie: MockFeedbackService!
  var dummyFeedback: Feedback!

  override func setUpWithError() throws {
    try super.setUpWithError()

    mockGeminiService = .init()
    mockFeedbackServie = .init()

    let continueContent = FeedbackContent(
      id: UUID(),
      content: "거친 말",
      spicy: .zero,
      visiable: true,
      type: .typeContinue,
      transContent: .none,
      cardState: .cover
    )
    
    let stopContent = FeedbackContent(
      id: UUID(),
      content: "하지 말아야 할 말",
      spicy: .zero,
      visiable: true,
      type: .typeStop,
      transContent: .none,
      cardState: .cover
    )

    dummyFeedback = Feedback(
      id: UUID(),
      feedbackChannelID: UUID(),
      readPerson: "user",
      writePerson: "writer",
      content: [continueContent, stopContent],
      date: Date(),
      visiable: true
    )

    sut = .init(
      feedbackItem: dummyFeedback,
      geminiService: mockGeminiService,
      feedbackService: mockFeedbackServie
    )

  }

  override func tearDownWithError() throws {
    sut = nil
    mockGeminiService = nil
    mockFeedbackServie = nil
    dummyFeedback = nil
    try super.tearDownWithError()
  }

  func test1_AI변환_성공시_데이터갱신_및_리스트업데이트_확인() async {
    // Given
    let transContent = "순화한 말"
    mockGeminiService.result = transContent
    
    guard let targetContent = sut.continueFeedbackList.first else {
      XCTFail("리스트에 아이템이 없음")
      return
    }
    
    // When
    await sut.transFeedbackContent(content: targetContent)
    
    // Then
    if let updatedItem = sut.continueFeedbackList.first(where: { $0.id == targetContent.id }) {
      XCTAssertEqual(updatedItem.transContent, transContent, "말이 순화되어야 함")
    } else {
      XCTFail("아이템 사라짐")
    }

    XCTAssertNil(sut.errorMessage, "성공 시 에러 메시지는 nil이어야 함")
    XCTAssertEqual(mockGeminiService.callCount, 1, "딱한 번 요청")
  }
  
  func test2_AI변환_실패시_에러메시지설정_및_상태롤백_확인() async {
    // Given
    struct TestError: Error, LocalizedError {
      var errorDescription: String? { "테스트용 에러" }
    }
    
    mockGeminiService.error = TestError()
    
    guard let targetContent = sut.continueFeedbackList.first else {
      XCTFail("리스트에 아이템이 없음")
      return
    }
    
    // When
    await sut.transFeedbackContent(content: targetContent)
    
    // Then
    XCTAssertFalse(sut.isTransLoading)
    XCTAssertEqual(sut.errorMessage, "변환 실패: 테스트용 에러")
    
    // Then
    if let updatedItem = sut.continueFeedbackList.first(where: { $0.id == targetContent.id }) {
      XCTAssertEqual(updatedItem.cardState, .cover, "실패시 카드는 cover 상태")
    } else {
      XCTFail("아이템 사라짐")
    }

    XCTAssertEqual(mockGeminiService.callCount, 1, "딱한 번 요청")
  }
  
  func test3_AI변환시_존재하지않는_ID전달시_변경사항없음() async {
    // Given
    // 리스트에 있는 content와 다른 id를 가지는 content 생성
    let testContent = FeedbackContent(
      id: UUID(),
      content: "나쁜 말",
      spicy: .zero,
      visiable: true,
      type: .typeContinue,
      transContent: .none,
      cardState: .cover
    )
    
    // AI는 정상 작동했다는 가정
    mockGeminiService.result = "순한한 말"
    
    // When
    await sut.transFeedbackContent(content: testContent)
    
    // Then
    XCTAssertFalse(sut.isTransLoading)
    
    guard let originalItem = sut.continueFeedbackList.first else { return }
    
    XCTAssertNil(originalItem.transContent, "ID가 다르므로 업데이트 되면 안됌")
    XCTAssertEqual(originalItem.content, "거친 말", "원래 내용 유지")
    
    XCTAssertEqual(mockGeminiService.callCount, 1)
  }
  
  func test4_AI변환시_다른_리스트는_영향받지_않음() async {
    // Given
    let initialStopCount = sut.stopFeedbackList.count
    let transContent = "순화한 말"
    mockGeminiService.result = transContent
    
    guard let targetContent = sut.continueFeedbackList.first else {
      XCTFail("Continue 리스트에 아이템이 없음")
      return
    }
    
    // When
    await sut.transFeedbackContent(content: targetContent)
    
    // Then
    XCTAssertEqual(sut.stopFeedbackList.count, initialStopCount, "Stop 리스트 개수는 변함 없어야 함")
  }
}
