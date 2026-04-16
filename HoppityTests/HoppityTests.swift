//
//  HoppityTests.swift
//  HoppityTests
//
//  Created by Sabyasachi Biswas on 16/04/26.
//

import Foundation
import Testing
@testable import Hoppity

struct HoppityTests {
    @Test
    func recordingHopCompletesGoalAndAdvancesStreak() {
        let progress = HopProgress(
            dailyGoal: 3,
            hopCount: 2,
            streakCount: 4,
            lastHopDate: "2026-04-16"
        )

        let updated = progress.recordHop(on: fixedDate(day: 16))

        #expect(updated.hopCount == 3)
        #expect(updated.streakCount == 5)
    }

    @Test
    func rollingForwardClearsIncompleteDay() {
        let progress = HopProgress(
            dailyGoal: 5,
            hopCount: 2,
            streakCount: 3,
            lastHopDate: "2026-04-16"
        )

        let updated = progress.rollForwardIfNeeded(today: fixedDate(day: 17))

        #expect(updated.hopCount == 0)
        #expect(updated.streakCount == 0)
        #expect(updated.lastHopDate == "2026-04-17")
    }

    private func fixedDate(day: Int) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(calendar: calendar, year: 2026, month: 4, day: day)
        return components.date!
    }
}
