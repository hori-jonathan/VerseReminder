import FirebaseFirestore
import SwiftUI

/// Simple creator UI for the new flexible ``ReadingPlan`` model. It only
/// covers a subset of all options but demonstrates how a user can configure
/// a goal and schedule.
struct PlanCreatorView: View {
    /// If non-nil the view edits an existing plan instead of creating a new one.
    var existingPlan: ReadingPlan?

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = "My Plan"
    @State private var goalType: ReadingPlanGoalType = .chaptersPerDay
    @State private var chaptersPerDay: Int = 1
    @State private var customPerDay: [String: Int] = [:]
    @State private var finishBy: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var startDate: Date = Date()
    @State private var notificationsEnabled: Bool = false
    @State private var notificationTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var customTimes: [String: Date] = [:]
    @State private var useCustomTimes: Bool = false
    @State private var readingDays: Set<String> = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    @State private var allowNonLinear: Bool = true
    @State private var preset: ReadingPlanPreset = .fullBible

    init(existingPlan: ReadingPlan? = nil) {
        self.existingPlan = existingPlan
        _name = State(initialValue: existingPlan?.name ?? "My Plan")
        _goalType = State(initialValue: existingPlan?.goalType ?? .chaptersPerDay)
        _chaptersPerDay = State(initialValue: existingPlan?.chaptersPerDay ?? 1)
        let defaults = Dictionary(uniqueKeysWithValues: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"].map { ($0, existingPlan?.chaptersPerDay ?? 1) })
        _customPerDay = State(initialValue: existingPlan?.chaptersPerDayByDay ?? defaults)
        _finishBy = State(initialValue: existingPlan?.finishBy ?? Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date())
        _startDate = State(initialValue: existingPlan?.startDate ?? Date())
        _notificationsEnabled = State(initialValue: existingPlan?.notificationsEnabled ?? false)
        let globalTime = existingPlan?.notificationTimeMinutes
            .flatMap { PlanCreatorView.minutesToDate($0) } ?? Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        _notificationTime = State(initialValue: globalTime)
        _useCustomTimes = State(initialValue: existingPlan?.notificationTimesByDay != nil)
        _customTimes = State(initialValue: existingPlan?.notificationTimesByDay?.mapValues { PlanCreatorView.minutesToDate($0) } ?? [:])
        _readingDays = State(initialValue: Set(existingPlan?.readingDays ?? ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]))
        _allowNonLinear = State(initialValue: existingPlan?.allowNonLinear ?? true)
        _preset = State(initialValue: existingPlan?.preset ?? .fullBible)
    }
    private let allDays = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

    static func dateToMinutes(_ date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    static func minutesToDate(_ minutes: Int) -> Date {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
    }

    var estimatedCompletion: Date {
        let plan = ReadingPlan(
            name: name,
            startDate: startDate,
            finishBy: goalType == .finishByDate ? finishBy : nil,
            chaptersPerDay: nil,
            chaptersPerDayByDay: customPerDay,
            readingDays: Array(readingDays),
            allowNonLinear: allowNonLinear,
            notificationsEnabled: notificationsEnabled,
            notificationTimeMinutes: notificationsEnabled ? PlanCreatorView.dateToMinutes(notificationTime) : nil,
            notificationTimesByDay: (notificationsEnabled && useCustomTimes) ? customTimes.mapValues { PlanCreatorView.dateToMinutes($0) } : nil,
            goalType: goalType,
            preset: preset,
            nodes: []
        )
        return plan.estimatedCompletion
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TextField("Plan Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Picker("Plan Preset", selection: $preset) {
                    ForEach(ReadingPlanPreset.allCases, id: \.self) { p in
                        Text(String(describing: p).capitalized).tag(p)
                    }
                }

                Picker("Goal", selection: $goalType) {
                    Text("Chapters/Day").tag(ReadingPlanGoalType.chaptersPerDay)
                    if existingPlan == nil {
                        Text("Finish By Date").tag(ReadingPlanGoalType.finishByDate)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onAppear {
                    if existingPlan != nil && goalType == .finishByDate {
                        goalType = .chaptersPerDay
                    }
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Chapters per Day: \(chaptersPerDay)")
                        Stepper("", value: $chaptersPerDay, in: 1...100)
                            .labelsHidden()
                        Slider(value: Binding(get: { Double(min(chaptersPerDay, 20)) }, set: { chaptersPerDay = Int($0) }), in: 1...20, step: 1)
                    }
                    .disabled(goalType != .chaptersPerDay)
                    ForEach(allDays, id: \.self) { day in
                        HStack {
                            Text(day)
                            Stepper("", value: Binding(get: { customPerDay[day] ?? chaptersPerDay }, set: { customPerDay[day] = min(max($0, 0), 100) }), in: 0...100)
                                .labelsHidden()
                            Slider(value: Binding(get: { Double(min(customPerDay[day] ?? chaptersPerDay, 20)) }, set: { customPerDay[day] = Int($0) }), in: 0...20, step: 1)
                            Text("\(customPerDay[day] ?? chaptersPerDay)")
                        }
                    }
                    DayPillarsView(values: $customPerDay, defaultValue: chaptersPerDay)
                        .frame(maxWidth: .infinity)
                }

                if existingPlan == nil {
                    VStack(alignment: .leading) {
                        DatePicker("Finish By", selection: $finishBy, displayedComponents: .date)
                    }
                    .disabled(goalType != .finishByDate)
                }

                VStack(alignment: .leading) {
                    Text("Reading Days")
                        .font(.headline)
                    HStack {
                        ForEach(allDays, id: \.self) { day in
                            Button(action: {
                                if readingDays.contains(day) { readingDays.remove(day) } else { readingDays.insert(day) }
                            }) {
                                Text(day)
                                    .padding(6)
                                    .background(readingDays.contains(day) ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }

                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                if notificationsEnabled {
                    DatePicker("Notification Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                    Toggle("Customize per-day times", isOn: $useCustomTimes)
                    if useCustomTimes {
                        ForEach(allDays, id: \.self) { day in
                            DatePicker(day, selection: Binding(get: { customTimes[day] ?? notificationTime }, set: { customTimes[day] = $0 }), displayedComponents: .hourAndMinute)
                        }
                    }
                }

                VStack(alignment: .leading) {
                    Text("Estimated completion")
                        .font(.headline)
                    Text(estimatedCompletion, style: .date)
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(existingPlan == nil ? "Create Plan" : "Edit Plan")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    let plan = ReadingPlan(
                        name: name,
                        startDate: startDate,
                        finishBy: goalType == .finishByDate ? finishBy : nil,
                        chaptersPerDay: nil,
                        chaptersPerDayByDay: customPerDay,
                        readingDays: Array(readingDays),
                        allowNonLinear: allowNonLinear,
                        notificationsEnabled: notificationsEnabled,
                        notificationTimeMinutes: notificationsEnabled ? PlanCreatorView.dateToMinutes(notificationTime) : nil,
                        notificationTimesByDay: (notificationsEnabled && useCustomTimes) ? customTimes.mapValues { PlanCreatorView.dateToMinutes($0) } : nil,
                        goalType: goalType,
                        preset: preset,
                        nodes: []
                    )
                    authViewModel.setReadingPlan(plan)
                    dismiss()
                }
            }
            if existingPlan != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        authViewModel.deleteReadingPlan()
                        dismiss()
                    } label: {
                        Text("Delete")
                    }
                }
            }
        }
    }
}

struct PlanCreatorView_Previews: PreviewProvider {
    static var previews: some View {
        PlanCreatorView()
            .environmentObject(AuthViewModel())
    }
}
