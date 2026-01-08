import Foundation

final class ChannelService: ChannelRepository {
  private let db = FirestoreManager.shared
  
  func create(_ channel: FeedbackChannel) async throws {
    _ = try await db.create(channel)
  }
  
  func get(id: String) async throws -> FeedbackChannel? {
    return try await db.get(id, collectionType: .feedbackChannel)
  }
  
  func fetch(userId: String) async throws -> [FeedbackChannel] {
    return try await db.fetch(
      as: FeedbackChannel.self,
      .feedbackChannel,
      whereFeild: "userID",
      equalData: userId
    )
  }
  
  func delete(_ channel: FeedbackChannel) async throws {
    return try await db.delete(channel)
  }
  
  func update(_ channel: FeedbackChannel) async throws {
    return try await db.update(channel)
  }
}
