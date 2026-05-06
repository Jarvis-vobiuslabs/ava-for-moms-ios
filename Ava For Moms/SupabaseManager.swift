import Supabase
import Foundation

// MARK: - Client singleton
// Add the Supabase Swift package in Xcode:
// File → Add Package Dependencies → https://github.com/supabase/supabase-swift
// Minimum version: 2.0.0

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://syhzfjrvbrqrsesxubtx.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5aHpmanJ2YnJxcnNlc3h1YnR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwOTEwOTYsImV4cCI6MjA5MzY2NzA5Nn0.6vXXbQkc0R7GdO3F8lES6bqnoxC5rgaBzaYz3R8t1Dg"
)

// MARK: - Database models

struct Profile: Codable, Identifiable {
    let id: UUID
    var name: String
    var workStatus: String
    var hasSchoolPickup: Bool
    var schoolPickupTime: String?
    var mentalLoadAreas: [String]
    var onboardingCompleted: Bool
    var avatarUrl: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case workStatus           = "work_status"
        case hasSchoolPickup      = "has_school_pickup"
        case schoolPickupTime     = "school_pickup_time"
        case mentalLoadAreas      = "mental_load_areas"
        case onboardingCompleted  = "onboarding_completed"
        case avatarUrl            = "avatar_url"
        case createdAt            = "created_at"
        case updatedAt            = "updated_at"
    }
}

struct FamilyMember: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var name: String
    var relationship: String   // "partner" | "child" | "other"
    var age: Int?
    var colorHex: String

    enum CodingKeys: String, CodingKey {
        case id, name, relationship, age
        case userId    = "user_id"
        case colorHex  = "color_hex"
    }
}

struct Task: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    var note: String?
    var dueDate: Date?
    var priority: String        // "urgent" | "normal" | "low"
    var completed: Bool
    var completedAt: Date?
    var familyMemberId: UUID?
    var source: String          // "user" | "ava"
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, note, priority, completed, source
        case userId          = "user_id"
        case dueDate         = "due_date"
        case completedAt     = "completed_at"
        case familyMemberId  = "family_member_id"
        case createdAt       = "created_at"
        case updatedAt       = "updated_at"
    }
}

struct CalendarEvent: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    var detail: String?
    var startsAt: Date
    var endsAt: Date?
    var allDay: Bool
    var colorHex: String
    var familyMemberId: UUID?
    var source: String          // "ava" | "eventkit" | "manual"
    var externalId: String?

    enum CodingKeys: String, CodingKey {
        case id, title, detail, source
        case userId          = "user_id"
        case startsAt        = "starts_at"
        case endsAt          = "ends_at"
        case allDay          = "all_day"
        case colorHex        = "color_hex"
        case familyMemberId  = "family_member_id"
        case externalId      = "external_id"
    }
}

struct GroceryList: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var storeName: String?
    var pickupTime: Date?
    var archived: Bool

    enum CodingKeys: String, CodingKey {
        case id, archived
        case userId      = "user_id"
        case storeName   = "store_name"
        case pickupTime  = "pickup_time"
    }
}

struct GroceryItem: Codable, Identifiable {
    let id: UUID
    let listId: UUID
    let userId: UUID
    var name: String
    var quantity: String?
    var category: String?
    var tag: String?
    var checked: Bool
    var addedBy: String         // "user" | "ava"

    enum CodingKeys: String, CodingKey {
        case id, name, quantity, category, tag, checked
        case listId   = "list_id"
        case userId   = "user_id"
        case addedBy  = "added_by"
    }
}

struct Message: Codable, Identifiable {
    let id: UUID
    let conversationId: UUID
    let userId: UUID
    var role: String            // "user" | "assistant"
    var content: String
    var model: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, role, content, model
        case conversationId  = "conversation_id"
        case userId          = "user_id"
        case createdAt       = "created_at"
    }
}

struct Subscription: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var tier: String            // "none" | "standard" | "pro"
    var status: String          // "active" | "inactive" | "trial" | "cancelled"
    var isAnnual: Bool
    var currentPeriodEndsAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, tier, status
        case userId                = "user_id"
        case isAnnual              = "is_annual"
        case currentPeriodEndsAt   = "current_period_ends_at"
    }

    var isActive: Bool { status == "active" || status == "trial" }
    var isPro: Bool    { isActive && tier == "pro" }
}

// MARK: - Auth helpers

extension SupabaseClient {
    var currentUserId: UUID? {
        // TODO: replace with async auth.session once wired
        nil
    }
}
