import SwiftUI

struct FirstTimeSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("setupComplete") private var setupComplete = false

    private let bibleOptions: [(name: String, id: String)] = [
        ("DRA", "bible_dra.sqlite"),
        ("ASV", "bible_asv.sqlite"),
        ("DBY", "bible_dby.sqlite"),
        ("KJV", "bible_kjv.sqlite"),
        ("WYC", "bible_wyc.sqlite")
    ]

    @State private var selectedBible: String = defaultBibleId
    @State private var planName: String = "My Plan"
    @State private var chaptersPerDay: Int = 1
    @State private var startDate: Date = Date()
    @State private var notificationsEnabled: Bool = false
    @State private var notificationTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Welcome to VerseReminder")
                        .font(.largeTitle).bold()
                        .padding(.top)

                    QuickSettingsPanel()
                        .environmentObject(authViewModel)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Bible Version")
                            .font(.headline)
                        Picker("Bible", selection: $selectedBible) {
                            ForEach(bibleOptions, id: .id) { opt in
                                Text(opt.name).tag(opt.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reading Plan & Notifications")
                            .font(.headline)
                        TextField("Plan Name", text: $planName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Stepper("Chapters per Day: \(chaptersPerDay)", value: $chaptersPerDay, in: 1...10)
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        if notificationsEnabled {
                            DatePicker("Notification Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    Button("Finish") {
                        authViewModel.updateBibleId(selectedBible)
                        let plan = ReadingPlan(
                            name: planName,
                            startDate: startDate,
                            chaptersPerDay: chaptersPerDay,
                            notificationsEnabled: notificationsEnabled,
                            notificationTimeMinutes: notificationsEnabled ? PlanCreatorView.dateToMinutes(notificationTime) : nil,
                            goalType: .chaptersPerDay,
                            preset: .fullBible,
                            nodes: []
                        )
                        authViewModel.setReadingPlan(plan)
                        authViewModel.saveProfile()
                        setupComplete = true
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)
                }
                .padding()
            }
            .navigationTitle("Setup")
            .onAppear {
                selectedBible = authViewModel.profile.bibleId
                planName = authViewModel.profile.readingPlan?.name ?? "My Plan"
                chaptersPerDay = authViewModel.profile.readingPlan?.chaptersPerDay ?? 1
                startDate = authViewModel.profile.readingPlan?.startDate ?? Date()
                notificationsEnabled = authViewModel.profile.readingPlan?.notificationsEnabled ?? false
                if let mins = authViewModel.profile.readingPlan?.notificationTimeMinutes {
                    notificationTime = PlanCreatorView.minutesToDate(mins)
                }
            }
        }
    }
}

struct FirstTimeSetupView_Previews: PreviewProvider {
    static var previews: some View {
        FirstTimeSetupView()
            .environmentObject(AuthViewModel())
    }
}

