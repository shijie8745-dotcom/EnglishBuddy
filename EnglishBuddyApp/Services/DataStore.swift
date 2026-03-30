import Foundation

class DataStore {
    static let shared = DataStore()
    private let defaults = UserDefaults.standard
    /// 串行队列保护 User 读写，防止并发竞态导致数据丢失
    private let userQueue = DispatchQueue(label: "com.englishbuddy.datastore.user")
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

    func saveUser(_ user: User) {
        userQueue.sync {
            if let data = try? JSONEncoder().encode(user) {
                defaults.set(data, forKey: "user")
            }
        }
    }

    static func loadUser() -> User {
        DataStore.shared.userQueue.sync {
            guard let data = DataStore.shared.defaults.data(forKey: "user"),
                  let user = try? JSONDecoder().decode(User.self, from: data) else {
                return User()
            }
            return user
        }
    }

    /// 原子操作：加载 User → 执行修改 → 保存，全程在串行队列中，防止并发覆盖
    func updateUser(_ mutate: (User) -> Void) {
        userQueue.sync {
            let user: User
            if let data = defaults.data(forKey: "user"),
               let decoded = try? JSONDecoder().decode(User.self, from: data) {
                user = decoded
            } else {
                user = User()
            }
            mutate(user)
            if let data = try? JSONEncoder().encode(user) {
                defaults.set(data, forKey: "user")
            }
        }
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
