import Foundation
import SwiftUI

// MARK: - Calendar Day Model

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let day: Int
    let isCurrentMonth: Bool
    let isCheckedIn: Bool
}

// MARK: - Cloud Shop ViewModel

@Observable
class CloudShopViewModel {
    private var user: User?
    private var calendar = Calendar.current
    private var displayedMonth: Date = Date()

    var totalCheckIns: Int = 0
    var consecutiveDays: Int = 0
    var isCheckedInToday: Bool = false
    var calendarDays: [CalendarDay] = []

    // Cloud coin stats
    var cloudCoins: Int = 0
    var totalEarned: Int = 0
    var todayChatCount: Int = 0

    // Pet shop
    var currentPetId: String = "yunbao"
    var allPets: [PetDefinition] = []

    var currentYear: Int {
        calendar.component(.year, from: displayedMonth)
    }

    var currentMonth: Int {
        calendar.component(.month, from: displayedMonth)
    }

    // MARK: - Data Loading

    func loadData(user: User) {
        // Always load fresh data from DataStore to get latest chat count
        let freshUser = DataStore.loadUser()
        self.user = freshUser
        loadCloudCoinData(user: freshUser)
        loadCheckInData(user: freshUser)
        loadPetData(user: freshUser)
    }

    /// 刷新数据（从 DataStore 重新加载最新数据）
    func refreshData() {
        let freshUser = DataStore.loadUser()
        self.user = freshUser
        loadCloudCoinData(user: freshUser)
        loadCheckInData(user: freshUser)
        loadPetData(user: freshUser)
    }

    private func loadCloudCoinData(user: User) {
        user.cloudCoinSystem.resetIfNewDay()
        cloudCoins = user.cloudCoinSystem.coins
        totalEarned = user.cloudCoinSystem.totalEarned
        todayChatCount = user.cloudCoinSystem.todayChatCount
    }

    private func loadCheckInData(user: User) {
        totalCheckIns = user.cloudCoinSystem.checkInRecords.count
        consecutiveDays = calculateConsecutiveDays(user: user)
        isCheckedInToday = user.cloudCoinSystem.isCheckedInToday
        generateCalendarDays(user: user)
    }

    private func loadPetData(user: User) {
        currentPetId = user.petCollection.currentPetId
        allPets = user.petCollection.allPetsSorted
    }

    // MARK: - Check-in

    /// 尝试打卡，返回获得的云朵币数量（0表示未满足条件）
    func tryCheckIn(user: User) -> Int {
        var earned = 0
        DataStore.shared.updateUser { freshUser in
            earned = freshUser.cloudCoinSystem.performCheckIn()
        }
        if earned > 0 {
            loadData(user: DataStore.loadUser())
        }
        return earned
    }

    /// 检查是否可以打卡（对话次数>=10且今日未打卡）
    var canCheckIn: Bool {
        guard let user = user else { return false }
        return user.cloudCoinSystem.canCheckIn
    }

    /// 获取打卡进度（对话次数/10）
    var checkInProgress: Int {
        min(todayChatCount, 10)
    }

    // MARK: - Pet Shop

    /// 购买宠物
    func purchasePet(petId: String, user: User) -> PurchaseResult {
        // Check if already unlocked
        guard !user.petCollection.isUnlocked(petId) else {
            return .alreadyOwned
        }

        // Check if enough coins
        guard user.cloudCoinSystem.coins >= CloudCoinReward.petPrice else {
            return .insufficientCoins
        }

        var success = false
        DataStore.shared.updateUser { freshUser in
            if freshUser.cloudCoinSystem.spendCoins(CloudCoinReward.petPrice) {
                if let pet = BuiltInPets.petById(petId) {
                    freshUser.petCollection.unlockPet(id: petId, name: pet.name)
                    success = true
                }
            }
        }

        if success {
            loadData(user: DataStore.loadUser())
            return .success
        }
        return .failed
    }

    /// 切换当前宠物
    func switchPet(to petId: String, user: User) -> Bool {
        var success = false
        DataStore.shared.updateUser { freshUser in
            success = freshUser.petCollection.switchToPet(id: petId)
        }
        if success {
            loadData(user: DataStore.loadUser())
        }
        return success
    }

    /// 检查宠物是否已解锁
    func isPetUnlocked(_ petId: String) -> Bool {
        guard let user = user else { return false }
        return user.petCollection.isUnlocked(petId)
    }

    // MARK: - Calendar Navigation

    func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newDate
            if let user = user {
                generateCalendarDays(user: user)
            }
        }
    }

    func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newDate
            if let user = user {
                generateCalendarDays(user: user)
            }
        }
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    // MARK: - Private Methods

    private func calculateConsecutiveDays(user: User) -> Int {
        let sortedRecords = user.cloudCoinSystem.checkInRecords.sorted { $0.date < $1.date }

        var consecutive = 0
        var checkDate = calendar.startOfDay(for: Date())

        for record in sortedRecords.reversed() {
            let recordDate = calendar.startOfDay(for: record.date)
            if calendar.isDate(recordDate, inSameDayAs: checkDate) {
                consecutive += 1
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                    checkDate = previousDay
                }
            } else if recordDate < checkDate {
                break
            }
        }

        return consecutive
    }

    private func generateCalendarDays(user: User) {
        calendarDays = []

        let year = calendar.component(.year, from: displayedMonth)
        let month = calendar.component(.month, from: displayedMonth)

        // Get first day of month
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let firstDayOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else {
            return
        }

        let daysInMonth = range.count

        // Get weekday of first day (1 = Sunday, 2 = Monday, 7 = Saturday in Gregorian calendar)
        // Convert to: 0 = Monday, 1 = Tuesday, ... 6 = Sunday (for display starting Monday)
        let weekdayComponent = calendar.component(.weekday, from: firstDayOfMonth)
        let firstWeekday = (weekdayComponent + 5) % 7  // Convert to Monday=0 format

        // Previous month days
        if firstWeekday > 0 {
            for i in 0..<firstWeekday {
                if let date = calendar.date(byAdding: .day, value: -(firstWeekday - i), to: firstDayOfMonth) {
                    calendarDays.append(CalendarDay(
                        date: date,
                        day: calendar.component(.day, from: date),
                        isCurrentMonth: false,
                        isCheckedIn: isDateCheckedIn(date, user: user)
                    ))
                }
            }
        }

        // Current month days
        for day in 1...daysInMonth {
            var dayComponents = DateComponents()
            dayComponents.year = year
            dayComponents.month = month
            dayComponents.day = day

            if let date = calendar.date(from: dayComponents) {
                calendarDays.append(CalendarDay(
                    date: date,
                    day: day,
                    isCurrentMonth: true,
                    isCheckedIn: isDateCheckedIn(date, user: user)
                ))
            }
        }

        // Next month days to fill grid (6 rows * 7 columns = 42 cells)
        let remainingCells = 42 - calendarDays.count
        for i in 1...remainingCells {
            if let date = calendar.date(byAdding: .day, value: daysInMonth - 1 + i, to: firstDayOfMonth) {
                calendarDays.append(CalendarDay(
                    date: date,
                    day: calendar.component(.day, from: date),
                    isCurrentMonth: false,
                    isCheckedIn: isDateCheckedIn(date, user: user)
                ))
            }
        }
    }

    private func isDateCheckedIn(_ date: Date, user: User) -> Bool {
        let startOfDate = calendar.startOfDay(for: date)
        return user.cloudCoinSystem.checkInRecords.contains { record in
            calendar.isDate(record.date, inSameDayAs: startOfDate)
        }
    }
}

// MARK: - Purchase Result

enum PurchaseResult {
    case success
    case insufficientCoins
    case alreadyOwned
    case failed
}
