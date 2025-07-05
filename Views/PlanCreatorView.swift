import FirebaseFirestore
import SwiftUI

struct PlanCreatorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var chaptersPerWeek: Int = 7
    @State private var notificationsEnabled: Bool = false
    @State private var startDate: Date = Date()

    var estimatedCompletion: Date {
        let plan = ReadingPlan(startDate: startDate, chaptersPerWeek: chaptersPerWeek, notificationsEnabled: notificationsEnabled)
        return plan.estimatedCompletion
    }

    var body: some View {
        Form {
            Section(header: Text("Reading Pace")) {
                Stepper(value: $chaptersPerWeek, in: 1...50) {
                    Text("Chapters per week: \(chaptersPerWeek)")
                }
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            }

            Section(header: Text("Estimate")) {
                Text("Estimated completion: \(estimatedCompletion, style: .date)")
            }
        }
        .navigationTitle("Create Plan")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    let plan = ReadingPlan(startDate: startDate, chaptersPerWeek: chaptersPerWeek, notificationsEnabled: notificationsEnabled)
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
