import SwiftUI

struct FirstTimeSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("setupComplete") private var setupComplete = false

    @State private var step = 0
    @State private var selectedTheme: AppTheme = .light
    private let bibleOptions: [(name: String, id: String)] = [
        ("DRA", "bible_dra.sqlite"),
        ("ASV", "bible_asv.sqlite"),
        ("DBY", "bible_dby.sqlite"),
        ("KJV", "bible_kjv.sqlite"),
        ("WYC", "bible_wyc.sqlite")
    ]
    @State private var selectedBible: String = defaultBibleId
    @State private var showPlanCreator = false
    @State private var notificationsEnabled = false
    @State private var notificationTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        ZStack {
            TabView(selection: $step) {
                themeStep.tag(0)
                bibleStep.tag(1)
                planStep.tag(2)
                notificationStep.tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .animation(.easeInOut, value: step)

            VStack {
                Spacer()
                HStack {
                    if step > 0 {
                        Button("Back") { step -= 1 }
                    }
                    Spacer()
                    if step < 3 {
                        Button("Next") { step += 1 }
                    } else {
                        Button("Finish") {
                            authViewModel.updateTheme(selectedTheme)
                            authViewModel.updateBibleId(selectedBible)
                            authViewModel.profile.readingPlan?.notificationsEnabled = notificationsEnabled
                            authViewModel.profile.readingPlan?.notificationTimeMinutes = notificationsEnabled ? PlanCreatorView.dateToMinutes(notificationTime) : nil
                            authViewModel.saveProfile()
                            setupComplete = true
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showPlanCreator) {
            NavigationView { PlanCreatorView() }
                .environmentObject(authViewModel)
        }
        .onAppear {
            selectedTheme = authViewModel.profile.theme
            selectedBible = authViewModel.profile.bibleId
            notificationsEnabled = authViewModel.profile.readingPlan?.notificationsEnabled ?? false
            if let mins = authViewModel.profile.readingPlan?.notificationTimeMinutes {
                notificationTime = PlanCreatorView.minutesToDate(mins)
            }
        }
    }

    private var themeStep: some View {
        VStack(spacing: 20) {
            Text("Choose a Theme")
                .font(.largeTitle).bold()
            HStack {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button(action: {
                        selectedTheme = theme
                        authViewModel.updateTheme(theme)
                    }) {
                        Circle()
                            .fill(theme.accentColor)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "checkmark.circle.fill")
                                    .opacity(selectedTheme == theme ? 1 : 0)
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
        }
        .padding()
    }

    private var bibleStep: some View {
        VStack(spacing: 20) {
            Text("Select Bible Version")
                .font(.largeTitle).bold()
            Picker("Bible", selection: $selectedBible) {
                ForEach(bibleOptions, id: \.id) { opt in
                    Text(opt.name).tag(opt.id)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .onChange(of: selectedBible) { authViewModel.updateBibleId($0) }
        }
        .padding()
    }

    private var planStep: some View {
        VStack(spacing: 20) {
            Text("Create a Reading Plan")
                .font(.largeTitle).bold()
            if authViewModel.profile.readingPlan != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.largeTitle)
            }
            Button(authViewModel.profile.readingPlan == nil ? "Create Plan" : "Edit Plan") {
                showPlanCreator = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var notificationStep: some View {
        VStack(spacing: 20) {
            Text("Notifications")
                .font(.largeTitle).bold()
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
            if notificationsEnabled {
                DatePicker("Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
            }
        }
        .padding()
    }
}

struct FirstTimeSetupView_Previews: PreviewProvider {
    static var previews: some View {
        FirstTimeSetupView()
            .environmentObject(AuthViewModel())
    }
}

