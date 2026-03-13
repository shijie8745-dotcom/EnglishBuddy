import Foundation
import Observation
import SwiftUI

@Observable
class CourseViewModel {
    var lessons: [Lesson] = []
    var pet: Pet
    var user: User
    var progress: [LessonProgress]
    private let dataStore = DataStore.shared

    init() {
        self.pet = DataStore.loadPet()
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

    // MARK: - Check-in Feature
    var totalCheckIns: Int {
        user.checkInRecords.count
    }

    var consecutiveDays: Int {
        calculateConsecutiveDays()
    }

    var isCheckedInToday: Bool {
        guard let lastCheckIn = user.checkInRecords.last?.date else { return false }
        return Calendar.current.isDateInToday(lastCheckIn)
    }

    func checkIn() -> Int {
        guard !isCheckedInToday else { return 0 }

        let consecutive = consecutiveDays
        var earnedCarrots = CheckInReward.daily

        // Bonus for consecutive days
        if consecutive >= 6 { // 7th day (0-indexed)
            earnedCarrots += CheckInReward.consecutive7Days
        } else if consecutive >= 2 { // 3rd day
            earnedCarrots += CheckInReward.consecutive3Days
        }

        let record = CheckInRecord(date: Date(), earnedCarrots: earnedCarrots, isBonus: consecutive >= 2)
        user.checkInRecords.append(record)
        user.currentCarrots += earnedCarrots
        user.totalCarrots += earnedCarrots

        dataStore.saveUser(user)
        return earnedCarrots
    }

    private func calculateConsecutiveDays() -> Int {
        let calendar = Calendar.current
        let sortedRecords = user.checkInRecords.sorted { $0.date < $1.date }

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

    // MARK: - Pet Feature
    func feedPet() -> Bool {
        guard user.currentCarrots > 0 else { return false }

        user.currentCarrots -= 1
        pet.feed()

        dataStore.saveUser(user)
        dataStore.savePet(pet)

        return true
    }

    func updatePetPosition(x: CGFloat, y: CGFloat) {
        pet.updatePosition(x: x, y: y)
        dataStore.savePet(pet)
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

        // Award carrots for studying (1 per minute)
        let earnedCarrots = studyTime * CheckInReward.studyPerMinute
        user.currentCarrots += earnedCarrots
        user.totalCarrots += earnedCarrots

        dataStore.saveUser(user)

        // Update pet experience
        pet.gainExperience(studyTime * 2)
        dataStore.savePet(pet)
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
}
