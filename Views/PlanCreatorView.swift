import FirebaseFirestore
import SwiftUI

/// Simple creator UI for the new flexible ``ReadingPlan`` model. It only
/// covers a subset of all options but demonstrates how a user can configure
/// a goal and schedule.
struct PlanCreatorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = "My Plan"
    @State private var goalType: ReadingPlanGoalType = .chaptersPerDay
    @State private var chaptersPerDay: Int = 1
    @State private var finishBy: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var startDate: Date = Date()
    @State private var notificationsEnabled: Bool = false
    @State private var readingDays: Set<String> = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    @State private var allowNonLinear: Bool = false

    private let allDays = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

    var estimatedCompletion: Date {
        let plan = ReadingPlan(
            name: name,
            startDate: startDate,
            finishBy: goalType == .finishByDate ? finishBy : nil,
            chaptersPerDay: goalType == .chaptersPerDay ? chaptersPerDay : nil,
            readingDays: Array(readingDays),
            allowNonLinear: allowNonLinear,
            notificationsEnabled: notificationsEnabled,
            goalType: goalType
        )
        return plan.estimatedCompletion
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TextField("Plan Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Picker("Goal", selection: $goalType) {
                    Text("Chapters/Day").tag(ReadingPlanGoalType.chaptersPerDay)
                    Text("Finish By Date").tag(ReadingPlanGoalType.finishByDate)
                }
                .pickerStyle(SegmentedPickerStyle())

                if goalType == .chaptersPerDay {
                    Stepper(value: $chaptersPerDay, in: 1...10) {
                        Text("\(chaptersPerDay) chapters per day")
                    }
                } else if goalType == .finishByDate {
                    DatePicker("Finish By", selection: $finishBy, displayedComponents: .date)
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

                Toggle("Allow Non-Linear Reading", isOn: $allowNonLinear)
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                Toggle("Enable Notifications", isOn: $notificationsEnabled)

                VStack(alignment: .leading) {
                    Text("Estimated completion")
                        .font(.headline)
                    Text(estimatedCompletion, style: .date)
                }
            }
            .padding()
        }
        .navigationTitle("Create Plan")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    let plan = ReadingPlan(
                        name: name,
                        startDate: startDate,
                        finishBy: goalType == .finishByDate ? finishBy : nil,
                        chaptersPerDay: goalType == .chaptersPerDay ? chaptersPerDay : nil,
                        readingDays: Array(readingDays),
                        allowNonLinear: allowNonLinear,
                        notificationsEnabled: notificationsEnabled,
                        goalType: goalType
                    )
                    authViewModel.setReadingPlan(plan)
                    dismiss()
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
