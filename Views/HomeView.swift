import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showPlanCreator = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                if let plan = authViewModel.profile.readingPlan {
                    Text("Total chapters read: \(authViewModel.profile.totalChaptersRead)")
                        .font(.headline)
                    Text("Plan: \(plan.chaptersPerWeek) chapters/week")
                        .foregroundColor(.secondary)
                    Text("Estimated completion: \(plan.estimatedCompletion, style: .date)")
                        .font(.caption)
                    if let last = lastReadReference() {
                        NavigationLink(destination: ChapterView(chapterId: last.ref, bibleId: defaultBibleId, highlightVerse: last.verse)) {
                            Text("Continue Reading")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("No reading plan yet")
                        Button("Create Plan") { showPlanCreator = true }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .sheet(isPresented: $showPlanCreator) {
                NavigationView { PlanCreatorView() }
            }
        }
    }

    private func lastReadReference() -> (ref: String, verse: Int)? {
        guard let book = authViewModel.profile.lastReadBookId,
              let info = authViewModel.profile.lastRead[book] else { return nil }
        let ref = "\(book).\(info["chapter"] ?? 1)"
        return (ref, info["verse"] ?? 0)
    }
}
