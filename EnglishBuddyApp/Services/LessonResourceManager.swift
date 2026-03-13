import Foundation

enum LessonResourceManager {
    static func loadLessonsFromJSON() -> [Lesson] {
        // Try without subdirectory first (for PBXFileSystemSynchronizedRootGroup)
        if let url = Bundle.main.url(forResource: "lessons", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                if let container = try? decoder.decode(LessonDataContainer.self, from: data) {
                    return container.lessons
                }
            } catch {
                print("Error loading lessons: \(error)")
            }
        }

        // Try with Resources subdirectory
        if let url = Bundle.main.url(forResource: "lessons", withExtension: "json",
                                        subdirectory: "Resources") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                if let container = try? decoder.decode(LessonDataContainer.self, from: data) {
                    return container.lessons
                }
            } catch {
                print("Error loading lessons from Resources: \(error)")
            }
        }

        return Lesson.mockLessons
    }
}

struct LessonDataContainer: Codable {
    let lessons: [Lesson]
}
