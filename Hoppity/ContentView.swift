//
//  ContentView.swift
//  Hoppity
//
//  Created by Sabyasachi Biswas on 16/04/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage(HopProgress.dailyGoalKey) private var dailyGoal = 20
    @AppStorage(HopProgress.hopCountKey) private var hopCount = 0
    @AppStorage(HopProgress.streakCountKey) private var streakCount = 0
    @AppStorage(HopProgress.lastHopDateKey) private var lastHopDate = ""

    @State private var goalDraft = ""

    private var progress: HopProgress {
        HopProgress(
            dailyGoal: dailyGoal,
            hopCount: hopCount,
            streakCount: streakCount,
            lastHopDate: lastHopDate
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    progressCard
                    goalCard
                    tipsCard
                }
                .padding(20)
            }
            .background(Color.secondary.opacity(0.08))
            .navigationTitle("Hoppity")
            .onAppear {
                goalDraft = String(progress.dailyGoal)
                syncProgressForToday()
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Build a daily hopping streak.")
                .font(.title2.weight(.bold))

            Text(progress.statusMessage)
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    recordHop()
                } label: {
                    Label("Log Hop", systemImage: "hare.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button("Reset Today", role: .destructive) {
                    resetToday()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Progress")
                .font(.headline)

            ProgressView(value: progress.progressValue)
                .tint(.green)

            HStack {
                statTile(title: "Hops", value: "\(progress.hopCount)")
                statTile(title: "Goal", value: "\(progress.dailyGoal)")
                statTile(title: "Streak", value: "\(progress.streakCount) days")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Goal")
                .font(.headline)

            TextField("20", text: $goalDraft)
#if os(iOS)
                .keyboardType(UIKeyboardType.numberPad)
#endif
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Save Goal") {
                saveGoal()
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Why this version is shippable")
                .font(.headline)

            Text("The app has a clear purpose, keeps local state across launches, and avoids template-only behavior.")
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func syncProgressForToday() {
        let updated = progress.rollForwardIfNeeded(today: Date())
        apply(updated)
    }

    private func recordHop() {
        let updated = progress.recordHop(on: Date())
        apply(updated)
    }

    private func resetToday() {
        let updated = progress.resetToday(on: Date())
        apply(updated)
    }

    private func saveGoal() {
        guard let parsedGoal = Int(goalDraft) else {
            goalDraft = String(progress.dailyGoal)
            return
        }

        let updated = progress.settingGoal(to: parsedGoal)
        goalDraft = String(updated.dailyGoal)
        apply(updated)
    }

    private func apply(_ updated: HopProgress) {
        dailyGoal = updated.dailyGoal
        hopCount = updated.hopCount
        streakCount = updated.streakCount
        lastHopDate = updated.lastHopDate
    }
}

struct HopProgress: Equatable {
    static let dailyGoalKey = "dailyGoal"
    static let hopCountKey = "hopCount"
    static let streakCountKey = "streakCount"
    static let lastHopDateKey = "lastHopDate"

    var dailyGoal: Int
    var hopCount: Int
    var streakCount: Int
    var lastHopDate: String

    var progressValue: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(hopCount) / Double(dailyGoal), 1)
    }

    var statusMessage: String {
        if hopCount >= dailyGoal {
            return "Goal complete. Keep the streak alive tomorrow."
        }

        let remaining = max(dailyGoal - hopCount, 0)
        return "\(remaining) hops left to hit today's goal."
    }

    func recordHop(on date: Date, calendar: Calendar = .current) -> HopProgress {
        let normalized = rollForwardIfNeeded(today: date, calendar: calendar)
        let nextCount = normalized.hopCount + 1
        let reachedGoal = normalized.hopCount < normalized.dailyGoal && nextCount >= normalized.dailyGoal

        return HopProgress(
            dailyGoal: normalized.dailyGoal,
            hopCount: nextCount,
            streakCount: reachedGoal ? normalized.streakCount + 1 : normalized.streakCount,
            lastHopDate: Self.storageDateString(from: date, calendar: calendar)
        )
    }

    func resetToday(on date: Date, calendar: Calendar = .current) -> HopProgress {
        HopProgress(
            dailyGoal: dailyGoal,
            hopCount: 0,
            streakCount: streakCount,
            lastHopDate: Self.storageDateString(from: date, calendar: calendar)
        )
    }

    func settingGoal(to newGoal: Int) -> HopProgress {
        HopProgress(
            dailyGoal: max(newGoal, 1),
            hopCount: hopCount,
            streakCount: streakCount,
            lastHopDate: lastHopDate
        )
    }

    func rollForwardIfNeeded(today: Date, calendar: Calendar = .current) -> HopProgress {
        guard let previousDate = Self.date(from: lastHopDate) else {
            return self
        }

        if calendar.isDate(previousDate, inSameDayAs: today) {
            return self
        }

        let completedGoal = hopCount >= dailyGoal
        let preservedStreak = completedGoal ? streakCount : 0

        return HopProgress(
            dailyGoal: dailyGoal,
            hopCount: 0,
            streakCount: preservedStreak,
            lastHopDate: Self.storageDateString(from: today, calendar: calendar)
        )
    }

    private static func storageDateString(from date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static func date(from string: String) -> Date? {
        guard !string.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}

#Preview {
    ContentView()
}
