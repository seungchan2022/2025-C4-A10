import Foundation

protocol FeedbackRepository {
  func create(_ feedback: Feedback) async throws -> Feedback
  func fetch(channelId: String) async throws -> [Feedback]
  func get(id: String) async throws -> Feedback?
  func delete(_ feedback: Feedback) async throws
  func update(_ feedback: Feedback) async throws
}
