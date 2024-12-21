import Foundation

struct JournalEntry: Codable {
    let date: Date
    let mood: String
    let text: String
}
