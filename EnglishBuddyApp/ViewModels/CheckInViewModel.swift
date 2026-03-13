import Foundation
import SwiftUI

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let day: Int
    let isCurrentMonth: Bool
    let isCheckedIn: Bool
}

@Observable
class CheckInViewModel {
    private var user: User?
    private var calendar = Calendar.current
    private var displayedMonth: Date = Date()

    var totalCheckIns: Int = 0
    var consecutiveDays: Int = 0
    var isCheckedInToday: Bool = false
    var calendarDays: [CalendarDay] = []

    var currentYear: Int {
        calendar.component(.year, from: displayedMonth)
    }

    var currentMonth: Int {
        calendar.component(.month, from: displayedMonth)
    }

    func loadCheckInData(user: User) {
        self.user = user
        totalCheckIns = user.checkInRecords.count
        consecutiveDays = calculateConsecutiveDays(user: user)
        isCheckedInToday = checkIsCheckedInToday(user: user)
        generateCalendarDays(user: user)
    }

    func checkIn(user: User) -> Int {
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

        DataStore.shared.saveUser(user)

        // Refresh data
        loadCheckInData(user: user)

        return earnedCarrots
    }

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
        let sortedRecords = user.checkInRecords.sorted { $0.date < $1.date }

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

    private func checkIsCheckedInToday(user: User) -> Bool {
        guard let lastCheckIn = user.checkInRecords.last?.date else { return false }
        return calendar.isDateInToday(lastCheckIn)
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

        // Get weekday of first day (0 = Sunday, 1 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1

        // Previous month days
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDayOfMonth),
           let prevRange = calendar.range(of: .day, in: .month, for: previousMonth) {
            let prevDaysCount = prevRange.count
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

        // Next month days to fill grid
        let remainingCells = 42 - calendarDays.count // 6 rows * 7 columns
        for i in 1...remainingCells {
            if let lastDayOfMonth = calendar.date(from: components),
               let date = calendar.date(byAdding: .day, value: daysInMonth + i - 1, to: lastDayOfMonth) {
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
        return user.checkInRecords.contains { record in
            calendar.isDate(record.date, inSameDayAs: startOfDate)
        }
    }
}
