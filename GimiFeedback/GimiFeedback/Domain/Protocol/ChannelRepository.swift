import Foundation

protocol ChannelRepository {
  func create(_ channel: FeedbackChannel) async throws
  func get(id: String) async throws -> FeedbackChannel?
  func fetch(userId: String) async throws -> [FeedbackChannel]
  func delete(_ channel: FeedbackChannel) async throws
  func update(_ channel: FeedbackChannel) async throws
}
