import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showPlanCreator = false
    @State private var editingPlan: ReadingPlan? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let plan = authViewModel.profile.readingPlan {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(plan.name)
                                .font(.title3).bold()

                            switch plan.goalType {
                            case .chaptersPerDay:
                                if let custom = plan.chaptersPerDayByDay {
                                    Text("Goal: variable chapters per day")
                                        .font(.subheadline)
                                } else {
                                    let amount = plan.chaptersPerDay ?? 1
                                    Text("Goal: \(amount) chapters per day")
                                        .font(.subheadline)
                                }
                            case .finishByDate:
                                if let end = plan.finishBy {
                                    Text("Finish by \(end, style: .date)")
                                        .font(.subheadline)
                                }
                            case .flexible:
                                Text("Flexible pace")
                                    .font(.subheadline)
                            }

                        ProgressView(value: Double(authViewModel.profile.totalChaptersRead), total: 1189)
                            .accentColor(.green)
                        Text("Estimated completion: \(plan.estimatedCompletion, style: .date)")
                            .font(.footnote)
                        Button("Edit Plan") {
                            editingPlan = plan
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    }

                        if let last = lastReadReference() {
                            NavigationLink(destination: ChapterView(chapterId: last.ref, bibleId: defaultBibleId, highlightVerse: last.verse)) {
                                Text("Continue Reading")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Text("No reading plan yet")
                                .font(.title2)
                            Button("Create Plan") { showPlanCreator = true }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showPlanCreator) {
                NavigationView { PlanCreatorView() }
            }
            .sheet(item: $editingPlan) { plan in
                NavigationView { PlanCreatorView(existingPlan: plan) }
            }
        }
    }

    private func lastReadReference() -> (ref: String, verse: Int)? {
        let all = (oldTestamentCategories + newTestamentCategories).flatMap { $0.books }.sorted { $0.order < $1.order }
        for book in all {
            let read = Set(authViewModel.profile.chaptersRead[book.id] ?? [])
            if let chapter = (1...book.chapters).first(where: { !read.contains($0) }) {
                return ("\(book.id).\(chapter)", 0)
            }
        }
        return nil
    }
}
