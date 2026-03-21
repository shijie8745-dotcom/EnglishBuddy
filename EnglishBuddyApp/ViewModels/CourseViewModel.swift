import Foundation
import Observation
import SwiftUI

@Observable
class CourseViewModel {
    var lessons: [Lesson] = []
    var user: User
    var progress: [LessonProgress]
    private let dataStore = DataStore.shared

    init() {
        self.user = DataStore.loadUser()
        self.progress = DataStore.loadProgress()
        self.lessons = LessonResourceManager.loadLessonsFromJSON()
    }

    var completedLessonsCount: Int {
        progress.filter { $0.isCompleted }.count
    }

    var totalStudyTime: Int {
        progress.reduce(0) { $0 + $1.totalStudyTime }
    }

    var totalSessions: Int {
        progress.reduce(0) { $0 + $1.studyCount }
    }

    // MARK: - Pet
    var currentPetName: String {
        user.petCollection.currentPet?.name ?? "云宝"
    }

    var currentPetImageName: String {
        user.petCollection.currentPetId
    }

    // MARK: - Practice Feature
    var practiceLesson: Lesson? {
        guard let lessonId = user.currentPracticeLessonId else {
            // Default to first lesson if none selected
            return lessons.first
        }
        return lessons.first { $0.id == lessonId }
    }

    func setPracticeLesson(_ lesson: Lesson) {
        user.currentPracticeLessonId = lesson.id
        dataStore.saveUser(user)
    }

    // MARK: - Check-in Feature (Cloud Coin System)
    var totalCheckIns: Int {
        user.cloudCoinSystem.checkInRecords.count
    }

    var consecutiveDays: Int {
        calculateConsecutiveDays()
    }

    var isCheckedInToday: Bool {
        user.cloudCoinSystem.isCheckedInToday
    }

    var cloudCoins: Int {
        user.cloudCoinSystem.coins
    }

    private func calculateConsecutiveDays() -> Int {
        let calendar = Calendar.current
        let sortedRecords = user.cloudCoinSystem.checkInRecords.sorted { $0.date < $1.date }

        var consecutive = 0
        var checkDate = calendar.startOfDay(for: Date())

        for record in sortedRecords.reversed() {
            let recordDate = calendar.startOfDay(for: record.date)
            if calendar.isDate(recordDate, inSameDayAs: checkDate) {
                consecutive += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if recordDate < checkDate {
                break
            }
        }

        return consecutive
    }

    // MARK: - Lesson Management
    func status(for lesson: Lesson) -> LessonStatus {
        // All lessons are now accessible
        if let lessonProgress = progress.first(where: { $0.id == lesson.id }) {
            if lessonProgress.isCompleted {
                return .completed
            }
            if lessonProgress.studyCount > 0 {
                return .inProgress
            }
        }
        // Return inProgress for all lessons so they're clickable
        return .inProgress
    }

    func startLesson(_ lesson: Lesson) {
        if let index = progress.firstIndex(where: { $0.id == lesson.id }) {
            progress[index].studyCount += 1
        } else {
            var newProgress = LessonProgress(id: lesson.id)
            newProgress.studyCount = 1
            progress.append(newProgress)
        }
        dataStore.saveProgress(progress)
    }

    func completeLesson(_ lesson: Lesson, studyTime: Int) {
        if let index = progress.firstIndex(where: { $0.id == lesson.id }) {
            progress[index].markAsCompleted()
            progress[index].addStudyTime(studyTime)
        } else {
            var newProgress = LessonProgress(id: lesson.id)
            newProgress.markAsCompleted()
            newProgress.addStudyTime(studyTime)
            newProgress.studyCount = 1
            progress.append(newProgress)
        }
        dataStore.saveProgress(progress)

        // Update user stats
        user.totalStudyTime += studyTime
        user.totalSessions += 1

        // Award cloud coins for studying (1 per minute)
        _ = user.cloudCoinSystem.earnCoinsFromStudy(minutes: studyTime)

        dataStore.saveUser(user)
    }

    func updateVoiceSpeed(_ speed: Float) {
        user.aiVoiceSpeed = speed
        dataStore.saveUser(user)
    }

    func uncompleteLesson(_ lesson: Lesson) {
        if let index = progress.firstIndex(where: { $0.id == lesson.id }) {
            progress[index].isCompleted = false
            progress[index].completedDate = nil
            dataStore.saveProgress(progress)
        }
    }

    // MARK: - Chat Session Tracking

    /// 记录一次对话，增加对话次数并检查是否可以打卡
    /// 返回获得的云朵币数量（如果触发了自动打卡）
    func recordChatSession() -> Int {
        user.cloudCoinSystem.incrementChatCount()

        // Try auto check-in
        let earned = user.cloudCoinSystem.performCheckIn()

        dataStore.saveUser(user)
        return earned
    }
}
