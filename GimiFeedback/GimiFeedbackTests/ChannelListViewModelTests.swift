import XCTest
@testable import GimiFeedback

@MainActor
final class ChannelListViewModelTests: XCTestCase {
  
  // SUT: System Under Test
  var sut: ChannelListViewModel!
  
  var mockChannelService: MockChannelService!
  var mockFeedbackService: MockFeedbackService!
  
  /// 각각의 테스트가 시작되기 직전에 실행되는 준비 단계 => 이전 테스트에서 썻던 객체를 다시 쓰지 않고,
  /// 항상 새 것으로 테스트 하기 위함
  /// - 1. Mock 객체 생성
  /// - 2. SUT (뷰모델) 생성
  // 매 테스트 시작 전 실햄됨
  override func setUpWithError() throws {
    try super.setUpWithError()
    
    // 1. 가짜 서비스들을 새것으로 생성
    mockChannelService = .init()
    mockFeedbackService = .init()
    
    // 2. 뷰모델을 생성하면서 가짜 서비스들 주입 (Injection)
    // => 이런식으로 뷰모델이 실제 DB가 아닌 우리가 설정한 가짜 서비스를 사용함
    sut = .init(
      channelService: mockChannelService,
      feedbackService: mockFeedbackService
    )
  }
  
  /// 각각의 테스트가 끝난 직후에 실행되는 정비 단계 => 메모리에서 깖끔하게 지워버리기 위함
  /// - 만들었던 객체(sut, mock)을 정리
  // 매 테스트 종료 후 실행
  override func tearDownWithError() throws {
    // 다 쓴 객체들 정리 (메모리 해제)
    sut = nil
    mockChannelService = nil
    mockFeedbackService = nil
    
    try super.tearDownWithError()
  }
  
  // 시나리오 1: 정상적으로 채널 목록을 가져오고, 피드백 개수가 합산 되는지 확인
  func test1_채널목록_조회_성공시_채널리스트와_총피드백수_계산이_정확해야함() async {
    //  1. Given (상황 설정) - "이런 데이터가 있다고 치자"
    XCTAssertFalse(sut.isChannelListLoading, "초기 상태는 로딩 중이 아님")
    
    // 1-1 채널 ID를 2개 생성
    let channelId1 = UUID()
    let channelId2 = UUID()
    
    // 1-2 채널 객체 2개 생성
    let channel1 = FeedbackChannel(
      id: channelId1,
      userID: "testUser",
      userName: "testUserName",
      channelTitle: "채널 1",
      content: "설명 1"
    )
    
    let channel2 = FeedbackChannel(
      id: channelId2,
      userID: "testUser",
      userName: "testUserName",
      channelTitle: "채널 2",
      content: "설명 2"
    )
    
    // 1-3 채널 세팅
    mockChannelService.fetchResult = [channel1, channel2]
    
    // 1-4 피드백 객체 생성
    // channel1에는 1개, channel2에는 0개라고 가정
    let feedback1 = Feedback(
      id: UUID(),
      feedbackChannelID: channelId1,
      readPerson: "user",
      writePerson: "writer",
      content: [],
      date: Date(),
      visiable: true
    )
    
    // 1-5 피드백 세팅
    mockFeedbackService.fetchResult = [
      channelId1.uuidString: [feedback1],
      channelId2.uuidString: [],
    ]
    
    // 2. When (행동 실행)
    
    await sut.fetchChannelList()

    // 3. Then (결과 검증) - "제대로 수행했는지 확인"
    
    // 3-1 채널이 2개가 잘 들어왓나?
    XCTAssertFalse(sut.isChannelListLoading, "함수가 불리고 나서 초기화 상태 확인")
    XCTAssertEqual(sut.channelList.count, 2, "채널 목록은 2개")
    
    // 3-2 전체 피드백 개수가 1개가 맞나?
    XCTAssertEqual(sut.totalFeedbackCount, 1, "총 피드백 개수가 1개")
    
    // 3-3 서비스들을 진짜로 호출하긴 했나? (호출 횟수 검증)
    XCTAssertEqual(mockChannelService.fetchCallCount, 1, "채널 목록 조회는 1번")
    XCTAssertEqual(mockFeedbackService.fetchCallCount, 2, "채널이 2개니까 피드백 조회도 2번")
    
  }
  
  func test2_채널이_없을때_빈배열_반환() async {
    // Given
    XCTAssertFalse(sut.isChannelListLoading, "초기 상태는 로딩 중이 아님")
    mockChannelService.fetchResult = []
    
    // When
    await sut.fetchChannelList()
    
    // Then
    XCTAssertFalse(sut.isChannelListLoading, "함수가 불리고 나서 초기화 상태 확인")
    XCTAssertEqual(sut.channelList.count, .zero, "채널 목록 비어있음")
    XCTAssertEqual(sut.totalFeedbackCount, .zero, "총 피드백 개수 0")
    
    XCTAssertEqual(mockChannelService.fetchCallCount, 1, "빈 배열이어도 조회 시도는 함")
    XCTAssertEqual(mockFeedbackService.fetchCallCount, .zero, "채널이 없으므로 피드백 조회가 이루어 지지 않음")
  }
  
  func test3_채널조회_실패() async {
    // Given
    XCTAssertFalse(sut.isChannelListLoading, "초기 상태는 로딩 중이 아님")
    
    struct TestError: Error, LocalizedError {
      var errorDescription: String? { "테스트용 에러" }
    }
    
    mockChannelService.fetchError = TestError()
    
    // When
    await sut.fetchChannelList()
    
    // Then
    XCTAssertFalse(sut.isChannelListLoading, "함수가 불리고 나서 초기화 상태 확인")
    XCTAssertEqual(sut.errorMessage, "테스트용 에러")
    XCTAssertEqual(sut.channelList.count, .zero, "에러 발생시 채널 목록 비어야 함")
    XCTAssertEqual(sut.totalFeedbackCount, .zero, "채널 조회에 에러가 발생했으므로 피드백 개수는 계산되지 않음")
    
    XCTAssertEqual(mockChannelService.fetchCallCount, 1, "조회 시도중 에러가 발생 함")
    XCTAssertEqual(mockFeedbackService.fetchCallCount, .zero, "채널을 조회 하던 중에러가 발생했으므로 피드백 조회 X")
    XCTAssertFalse(sut.isChannelListLoading, "함수가 불리고 나서 초기화 상태 확인")
  }
  
  func test4_피드백_조회중_에러발생시_전체조회는_실패처리() async {
    // Given
    XCTAssertFalse(sut.isChannelListLoading)
    
    let channelId1 = UUID()
    let channelId2 = UUID()
    
    let channel1 = FeedbackChannel(
      id: channelId1,
      userID: "testUser",
      userName: "testUserName",
      channelTitle: "채널 1",
      content: "설명 1"
    )
    
    let channel2 = FeedbackChannel(
      id: channelId2,
      userID: "testUser",
      userName: "testUserName",
      channelTitle: "채널 2",
      content: "설명 2"
    )
    
    mockChannelService.fetchResult = [channel1, channel2]

    struct FeedbackError: Error, LocalizedError {
      var errorDescription: String? { "피드백 가져오기 에러"}
    }
    
    mockFeedbackService.fetchError = FeedbackError()
    
    // When
    await sut.fetchChannelList()
    
    // Then
    XCTAssertFalse(sut.isChannelListLoading)
    XCTAssertEqual(sut.errorMessage, "피드백 가져오기 에러")
    XCTAssertEqual(sut.channelList.count, .zero, "에러 발생시 채널 목록 비어야 함")
    XCTAssertEqual(sut.totalFeedbackCount, .zero, "총 피드백 개수 0")
    
    XCTAssertEqual(mockChannelService.fetchCallCount, 1, "채널 조회는 성공 했음")
    XCTAssertGreaterThanOrEqual(mockFeedbackService.fetchCallCount, 1, "1번은 피드백 조회를 시도했어야 함")

  }
}
