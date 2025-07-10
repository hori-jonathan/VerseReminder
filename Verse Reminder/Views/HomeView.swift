import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var booksNav: BooksNavigationManager
    @EnvironmentObject var tabManager: TabSelectionManager

    @State private var showPlanCreator = false
    @State private var editingPlan: ReadingPlan? = nil
    @State private var showReset = false
    @State private var showAdvanced = false
    @State private var showContact = false
    @State private var showPrivacy = false

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
                                if let _ = plan.chaptersPerDayByDay {
                                    Text(plan.readingDaysMessage)
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

                    if let plan = authViewModel.profile.readingPlan {
                        let goal = plan.chaptersForDate(Date())
                        let read = authViewModel.profile.todayChaptersRead
                        if goal > 0 {
                            VStack(spacing: 12) {
                                Text("Today's Progress")
                                    .font(.headline)
                                    .padding(.bottom, read >= goal ? 4 : 0)
                                DailyProgressCircle(progress: Double(read) / Double(goal))
                                if read >= goal {
                                    Text("Today's goal completed!")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.gray)
                                        .padding(.top, 4)
                                } else {
                                    Text("You've read \(read) of \(goal) chapters today")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                if read < goal, let last = lastReadReference() {
                                    Button(action: {
                                        let parts = last.ref.split(separator: ".")
                                        let bookId = String(parts[0])
                                        let chapter = Int(parts[1]) ?? 1
                                        booksNav.openChapter(bookId: bookId, chapter: chapter, highlight: last.verse, tabManager: tabManager)
                                    }) {
                                        Text("Continue where you left off")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    }
                    HomeSettingsView(showAdvanced: $showAdvanced, showContact: $showContact, showPrivacy: $showPrivacy)
                    DonateSectionView()
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
            .sheet(isPresented: $showReset) {
                ResetAccountView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showAdvanced) {
                NavigationView { AdvancedSettingsView() }
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showContact) {
                NavigationView { ContactView() }
            }
            .sheet(isPresented: $showPrivacy) {
                NavigationView { PrivacyPolicyView() }
            }
        }
        .navigationViewStyle(.stack)
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
