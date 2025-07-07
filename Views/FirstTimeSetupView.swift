import SwiftUI

/// Modernized multi-step setup flow displayed on first launch.
struct FirstTimeSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("setupComplete") private var setupComplete = false

    // Full translation names used across the app
    private let bibleOptions: [(name: String, id: String)] = [
        ("Douay-Rheims", "bible_dra.sqlite"),
        ("American Standard Version", "bible_asv.sqlite"),
        ("Darby Bible", "bible_dby.sqlite"),
        ("King James Version", "bible_kjv.sqlite"),
        ("Wycliffe Bible", "bible_wyc.sqlite")
    ]

    private let allDays = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

    @State private var selectedBible: String = defaultBibleId
    @State private var chaptersPerDay: Int = 1
    @State private var customPerDay: [String: Int] = [:]
    @State private var notificationsEnabled: Bool = false
    @State private var notificationTimes: [Date] = [
        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    ]
    @State private var page = 0
    @State private var showWelcome = false
    @State private var showQuick = false
    @State private var showBible = false
    @State private var showPlan = false

    private var estimatedCompletion: Date {
        let plan = ReadingPlan(
            chaptersPerDay: nil,
            chaptersPerDayByDay: customPerDay,
            notificationsEnabled: notificationsEnabled,
            notificationTimeMinutes: (notificationsEnabled && notificationTimes.count == 1) ?
                PlanCreatorView.dateToMinutes(notificationTimes[0]) : nil,
            notificationTimesByDay: (notificationsEnabled && notificationTimes.count > 1) ?
                Dictionary(uniqueKeysWithValues: notificationTimes.enumerated().map { ("t\($0.offset)", PlanCreatorView.dateToMinutes($0.element)) }) : nil,
            goalType: .chaptersPerDay,
            preset: .fullBible,
            nodes: []
        )
        return plan.estimatedCompletion
    }

    var body: some View {
        NavigationView {
            TabView(selection: $page) {
                // Slide 0: welcome
                VStack(spacing: 24) {
                    (Text("Welcome to ") + Text("VerseReminder").foregroundColor(.purple))
                        .font(.largeTitle).bold()
                        .opacity(showWelcome ? 1 : 0)
                        .onAppear { showWelcome = true }
                    Text("Swipe to continue")
                        .font(.headline)
                        .opacity(showWelcome ? 1 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tag(0)

                // Slide 1: quick settings
                VStack(spacing: 16) {
                    Text("UI Preferences")
                        .font(.headline)
                        .opacity(0.7)
                    QuickSettingsPanel(showBiblePicker: false)
                        .environmentObject(authViewModel)
                        .opacity(showQuick ? 1 : 0)
                        .onAppear { showQuick = true }
                }
                .padding()
                .tag(1)

                // Slide 2: bible version
                VStack(spacing: 16) {
                    Text("Bible Version")
                        .font(.headline)
                    Picker("Bible", selection: $selectedBible) {
                        ForEach(bibleOptions, id: \.id) { opt in
                            Text(opt.name).tag(opt.id)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .opacity(showBible ? 1 : 0)
                .onAppear { showBible = true }
                .tag(2)

                // Slide 3: plan and notifications
                ScrollView {
                    GeometryReader { geo in
                        VStack(spacing: 16) {
                            Text("Reading Plan")
                                .font(.headline)

                        HStack(spacing: 24) {
                            Button(action: {
                                chaptersPerDay = min(10, chaptersPerDay + 1)
                                for d in allDays {
                                    let current = customPerDay[d] ?? chaptersPerDay
                                    customPerDay[d] = min(10, current + 1)
                                }
                            }) {
                                Label("+1", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.bordered)

                            Button(action: {
                                chaptersPerDay = max(1, chaptersPerDay - 1)
                                for d in allDays {
                                    let current = customPerDay[d] ?? chaptersPerDay
                                    customPerDay[d] = max(0, current - 1)
                                }
                            }) {
                                Label("-1", systemImage: "minus.circle.fill")
                            }
                            .buttonStyle(.bordered)
                        }

                        DayPillarsView(values: $customPerDay, defaultValue: chaptersPerDay)

                        Text("Estimated completion: \(estimatedCompletion, style: .date)")
                            .font(.subheadline)

                        Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        if notificationsEnabled {
                            VStack(spacing: 8) {
                                ForEach(notificationTimes.indices, id: \.self) { idx in
                                    HStack {
                                        DatePicker("Time \(idx + 1)", selection: $notificationTimes[idx], displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                        Spacer()
                                        Button(action: { notificationTimes.remove(at: idx) }) {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)
                                }
                                Button(action: {
                                    notificationTimes.append(Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date())
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Time")
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height, alignment: .center)
                        .padding(.bottom)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .opacity(showPlan ? 1 : 0)
                .onAppear { showPlan = true }
                .tag(3)
            }
            .tabViewStyle(PageTabViewStyle())
            .navigationBarTitle("Setup", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if page > 0 { Button("Back") { page -= 1 } }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if page < 3 {
                        Button("Next") { page += 1 }
                    } else {
                        Button("Finish") { save() }
                    }
                }
            }
            .onAppear {
                selectedBible = authViewModel.profile.bibleId
                chaptersPerDay = authViewModel.profile.readingPlan?.chaptersPerDay ?? 1
                customPerDay = authViewModel.profile.readingPlan?.chaptersPerDayByDay ??
                    Dictionary(uniqueKeysWithValues: allDays.map { ($0, chaptersPerDay) })
                notificationsEnabled = authViewModel.profile.readingPlan?.notificationsEnabled ?? false
                if let mins = authViewModel.profile.readingPlan?.notificationTimeMinutes {
                    notificationTimes = [PlanCreatorView.minutesToDate(mins)]
                }
                if let times = authViewModel.profile.readingPlan?.notificationTimesByDay {
                    notificationTimes = times.keys.sorted().compactMap { key in
                        if let val = times[key] { return PlanCreatorView.minutesToDate(val) } else { return nil }
                    }
                }
                showWelcome = true
            }
        }
    }

    private func save() {
        authViewModel.updateBibleId(selectedBible)
        let plan = ReadingPlan(
            chaptersPerDay: nil,
            chaptersPerDayByDay: customPerDay,
            notificationsEnabled: notificationsEnabled,
            notificationTimeMinutes: (notificationsEnabled && notificationTimes.count == 1) ?
                PlanCreatorView.dateToMinutes(notificationTimes[0]) : nil,
            notificationTimesByDay: (notificationsEnabled && notificationTimes.count > 1) ?
                Dictionary(uniqueKeysWithValues: notificationTimes.enumerated().map { ("t\($0.offset)", PlanCreatorView.dateToMinutes($0.element)) }) : nil,
            goalType: .chaptersPerDay,
            preset: .fullBible,
            nodes: []
        )
        authViewModel.setReadingPlan(plan)
        authViewModel.saveProfile()
        setupComplete = true
    }
}

/// Simple column chart to adjust per-day chapter counts.
struct DayPillarsView: View {
    @Binding var values: [String: Int]
    var defaultValue: Int
    private let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(days, id: \.self) { day in
                VStack {
                    let val = min(values[day] ?? defaultValue, 10)
                    let color = Color(hue: max(0.0, 0.33 - Double(val)/60.0), saturation: 0.8, brightness: 0.9)
                    Rectangle()
                        .fill(color)
                        .frame(width: 30, height: CGFloat(val) * 16)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    let delta = Int(-value.translation.height / 20)
                                    let current = values[day] ?? defaultValue
                                    let newVal = max(0, current + delta)
                                    values[day] = min(10, newVal)
                                }
                        )
                        .onTapGesture {
                            let newVal = (values[day] ?? defaultValue) + 1
                            values[day] = min(10, newVal)
                        }
                    Text(String(day.prefix(3)))
                        .font(.caption2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.default, value: values)
    }
}

struct FirstTimeSetupView_Previews: PreviewProvider {
    static var previews: some View {
        FirstTimeSetupView()
            .environmentObject(AuthViewModel())
    }
}

