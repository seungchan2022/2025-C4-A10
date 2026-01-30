//
//  FeedbackDetailViewModel.swift
//  GimiFeedback
//
//  Created by 조운경 on 7/15/25.
//

import Foundation

final class FeedbackDetailViewModel: ViewModelable {

  enum Action {
    case deleteFeedback
    case updateFeedbackVisibility
    case transContent(FeedbackContent)
    case updateCardState(FeedbackContent)
  }

  var feedbackItem: Feedback
  @Published var continueFeedbackList: [FeedbackContent]
  @Published var stopFeedbackList: [FeedbackContent]
  @Published private(set) var errorMessage: String?
  @Published var isDeleted = false
  @Published var isShowToast = false

  @Published private(set) var isDeleteLoading: Bool = false
  @Published private(set) var isTransLoading: Bool = false
  @Published private(set) var isUpdateCardStateLoading: Bool = false
  @Published private(set) var isUpdateVisibleLoading: Bool = false

  private let geminiService: GeminiRepository
  private let feedbackService: FeedbackRepository

  var isLoading: Bool {
    isDeleteLoading
      || isUpdateVisibleLoading
  }

  init(
    feedbackItem: Feedback,
    geminiService: GeminiRepository = GeminiService(),
    feedbackService: FeedbackRepository = FeedbackService()
  ) {
    self.feedbackItem = feedbackItem
    self.continueFeedbackList = feedbackItem.content.filter {
      $0.type == .typeContinue
    }
    self.stopFeedbackList = feedbackItem.content.filter { $0.type == .typeStop }
    self.geminiService = geminiService
    self.feedbackService = feedbackService
  }

  func send(_ action: Action) {
    switch action {
    case .deleteFeedback:
      deleteFeedback(feedbackItem: feedbackItem)
    case .updateFeedbackVisibility:
      feedbackItem.visiable = true
      updateFeedbackVisibility()
    case .transContent(let content):
      Task {
       await transFeedbackContent(content: content)
      }
    case .updateCardState(let detail):
      updateCardState(detail: detail)
    }
  }
}

extension FeedbackDetailViewModel {
  private func deleteFeedback(feedbackItem: Feedback) {
    Task {
      isDeleteLoading = true
      do {
        try await feedbackService.delete(feedbackItem)
        print("피드백 삭제 성공")
        isDeleted = true
      } catch {
        errorMessage = "삭제 실패: \(error.localizedDescription)"
        print("삭제 실패: \(error.localizedDescription)")
      }
      isDeleteLoading = false
    }
  }

  func transFeedbackContent(content: FeedbackContent) async {
    isTransLoading = true
    defer { isTransLoading = false }
    do {
      // 생성형 AI 관련해서 여기서 에러가 발생하므로 do 구문 안으로 넣어줘야 함
      let response = try await geminiService.generate(
        inputText: content.content
      )

      guard let index = feedbackItem.content.firstIndex(where: { $0.id == content.id })
      else { return }

      feedbackItem.content[index].transContent = response
      
      try await commitChange()
    } catch {
      rollbackState(error: error, content: content)
    }
  }
  
  private func commitChange() async throws {
    
    // typeContinue인 리스트틀
    continueFeedbackList = feedbackItem.content.filter {
      $0.type == .typeContinue
    }
    stopFeedbackList = feedbackItem.content.filter { $0.type == .typeStop }

    try await feedbackService.update(feedbackItem)
  }
  
  private func rollbackState(error: Error, content: FeedbackContent) {
    // 에러 발생 시 사용자에게 메시지 표시
    errorMessage = "변환 실패: \(error.localizedDescription)"
    print("변환 실패: \(error.localizedDescription)")

    // [Rollback] 에러 발생 시 카드의 상태를 초기화(.cover)하여 무한 로딩 방지
    if let index = feedbackItem.content.firstIndex(where: {
      $0.id == content.id
    }) {
      feedbackItem.content[index].cardState = .cover

      // UI 즉시 갱신
      continueFeedbackList = feedbackItem.content.filter {
        $0.type == .typeContinue
      }
      stopFeedbackList = feedbackItem.content.filter {
        $0.type == .typeStop
      }
    }
  }

  private func updateCardState(detail: FeedbackContent) {
    guard
      let index = feedbackItem.content.firstIndex(where: { $0.id == detail.id })
    else { return }

    feedbackItem.content[index].cardState = detail.cardState

    if feedbackItem.content[index].cardState == .trans,
      feedbackItem.content[index].transContent == nil  {
      return
    }

    continueFeedbackList = feedbackItem.content.filter {
      $0.type == .typeContinue
    }
    stopFeedbackList = feedbackItem.content.filter { $0.type == .typeStop }

    Task {
      isUpdateCardStateLoading = true
      do {
        try await feedbackService.update(feedbackItem)
      } catch {
        errorMessage = "원문 표시 실패: \(error.localizedDescription)"
        print("원문 표시 실패: \(error.localizedDescription)")
      }
      isUpdateCardStateLoading = false
    }
  }

  private func updateFeedbackVisibility() {
    Task {
      isUpdateVisibleLoading = true
      do {
        try await feedbackService.update(feedbackItem)
      } catch {
        errorMessage = "원문 표시 실패: \(error.localizedDescription)"
        print("원문 표시 실패: \(error.localizedDescription)")
      }
      isUpdateVisibleLoading = false
    }
  }
}
