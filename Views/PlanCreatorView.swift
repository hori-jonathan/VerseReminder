import FirebaseFirestore
import SwiftUI

struct PlanCreatorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var dailyChapters: [String: Int] = [
        "Mon": 1, "Tue": 1, "Wed": 1, "Thu": 1, "Fri": 1, "Sat": 1, "Sun": 1
    ]
    @State private var notificationsEnabled: Bool = false
    @State private var startDate: Date = Date()

    var estimatedCompletion: Date {
        let plan = ReadingPlan(startDate: startDate, dailyChapters: dailyChapters, notificationsEnabled: notificationsEnabled)
        return plan.estimatedCompletion
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Weekly Schedule")
                        .font(.title2).bold()
                    ForEach(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"], id: \.self) { day in
                        Stepper(value: Binding(get: { dailyChapters[day] ?? 0 }, set: { dailyChapters[day] = $0 }), in: 0...10) {
                            Text("\(day): \(dailyChapters[day] ?? 0) chapters")
                        }
                    }
                }

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
                    let plan = ReadingPlan(startDate: startDate, dailyChapters: dailyChapters, notificationsEnabled: notificationsEnabled)
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
