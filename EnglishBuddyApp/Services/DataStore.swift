import Foundation

class DataStore {
    static let shared = DataStore()
    private let defaults = UserDefaults.standard
    private init() {}

    func saveCompanion(_ companion: Companion) {
        if let data = try? JSONEncoder().encode(companion) {
            defaults.set(data, forKey: "companion")
        }
    }

    static func loadCompanion() -> Companion {
        guard let data = DataStore.shared.defaults.data(forKey: "companion"),
              let companion = try? JSONDecoder().decode(Companion.self, from: data) else {
            return Companion()
        }
        return companion
    }

    // MARK: - Pet
    func savePet(_ pet: Pet) {
        if let data = try? JSONEncoder().encode(pet) {
            defaults.set(data, forKey: "pet")
        }
    }

    static func loadPet() -> Pet {
        guard let data = DataStore.shared.defaults.data(forKey: "pet"),
              let pet = try? JSONDecoder().decode(Pet.self, from: data) else {
            return Pet()
        }
        return pet
    }

    func saveUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: "user")
        }
    }

    static func loadUser() -> User {
        guard let data = DataStore.shared.defaults.data(forKey: "user"),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return User()
        }
        return user
    }

    func saveProgress(_ progress: [LessonProgress]) {
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: "progress")
        }
    }

    static func loadProgress() -> [LessonProgress] {
        guard let data = DataStore.shared.defaults.data(forKey: "progress"),
              let progress = try? JSONDecoder().decode([LessonProgress].self, from: data) else {
            return []
        }
        return progress
    }

    func saveUserAvatar(_ imageData: Data) {
        defaults.set(imageData, forKey: "userAvatar")
    }

    static func loadUserAvatar() -> Data? {
        DataStore.shared.defaults.data(forKey: "userAvatar")
    }
}

struct LessonDataLoader {
    static func loadAllLessons() -> [Lesson] {
        return LessonResourceManager.loadLessonsFromJSON()
    }

    static func loadLesson(id: Int) -> Lesson? {
        loadAllLessons().first { $0.id == id }
    }
}
