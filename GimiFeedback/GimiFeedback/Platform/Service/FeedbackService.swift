import Foundation

final class FeedbackService: FeedbackRepository {
  private let db = FirestoreManager.shared
  
  func create(_ feedback: Feedback) async throws -> Feedback {
    return try await db.create(feedback)
  }
  
  func fetch(channelId: String) async throws -> [Feedback] {
    return try await db.fetch(
      as: Feedback.self,
      .feedback,
      whereFeild: "feedbackChannelID",
      equalData: channelId
    )
  }
  
  func get(id: String) async throws -> Feedback? {
    return try await db.get(id, collectionType: .feedback)
  }
  
  func delete(_ feedback: Feedback) async throws {
    return try await db.delete(feedback)
  }
  
  func update(_ feedback: Feedback) async throws {
    return try await db.update(feedback)
  }
}
