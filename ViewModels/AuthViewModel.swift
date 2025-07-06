import Foundation
import FirebaseAuth
import GoogleSignIn

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = true
    @Published var error: Error?
    @Published var profile = UserProfile()
    /// Published celebration event used to trigger visual effects.
    @Published var celebrationEvent: CelebrationEvent?

    private var signInRetries = 0

    private var listener: AuthStateDidChangeListenerHandle?
    private let dataStore = UserDataStore()

    init() {
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    /// Call this after Firebase has been configured to begin authentication.
    func start() {
        signInAnonymouslyIfNeeded()
    }

    deinit {
        if let listener = listener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    func signInAnonymouslyIfNeeded() {
        isLoading = true
        if Auth.auth().currentUser == nil {
            attemptAnonymousSignIn()
        } else {
            self.user = Auth.auth().currentUser
            self.isLoading = false
            if let uid = self.user?.uid { self.loadProfile(uid: uid) }
        }
    }

    private func attemptAnonymousSignIn() {
        Auth.auth().signInAnonymously { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.signInRetries += 1
                    let nsError = error as NSError
                    print("Anonymous sign-in failed:", nsError, nsError.userInfo)
                    if nsError.code == AuthErrorCode.internalError.rawValue,
                       let underlying = nsError.userInfo[NSUnderlyingErrorKey] {
                        print("Underlying error:", underlying)
                    }
                    if self?.signInRetries ?? 0 < 3 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self?.attemptAnonymousSignIn()
                        }
                    } else {
                        self?.isLoading = false
                        self?.error = error
                    }
                } else {
                    self?.isLoading = false
                    self?.user = result?.user
                    if let uid = result?.user.uid { self?.loadProfile(uid: uid) }
                }
            }
        }
    }

    func linkWithGoogle(completion: @escaping (Error?) -> Void) {
        guard let topVC = UIApplication.shared.windows.first?.rootViewController else {
            completion(NSError(domain: "UI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Root VC"]))
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: topVC) { result, error in
            if let error = error {
                completion(error)
                return
            }
            guard let idToken = result?.user.idToken?.tokenString,
                  let accessToken = result?.user.accessToken.tokenString
            else {
                completion(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"]))
                return
            }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            self.link(with: credential, completion: completion)
        }
    }

    func linkWithEmail(email: String, password: String, completion: @escaping (Error?) -> Void) {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        link(with: credential, completion: completion)
    }

    func link(with credential: AuthCredential, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"]))
            return
        }
        user.link(with: credential) { result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self.user = result.user
                    completion(nil)
                } else {
                    completion(error)
                }
            }
        }
    }

    private func loadProfile(uid: String) {
        dataStore.loadProfile(uid: uid) { profile, _ in
            DispatchQueue.main.async { [weak self] in
                self?.profile = profile ?? UserProfile()
            }
        }
    }

    func saveProfile() {
        guard let uid = user?.uid else { return }
        dataStore.saveProfile(profile, uid: uid, completion: nil)
    }

    func markChapterRead(bookId: String, chapter: Int, verse: Int) {
        var set = Set(profile.chaptersRead[bookId] ?? [])
        let wasNew = !set.contains(chapter)
        if wasNew {
            set.insert(chapter)
            profile.chaptersRead[bookId] = Array(set).sorted()
            let key = Date().isoDateString
            profile.dailyChapterCounts[key, default: 0] += 1
        }
        profile.lastRead[bookId] = ["chapter": chapter, "verse": verse]
        profile.lastReadBookId = bookId
        saveProfile()

        if wasNew {
            triggerCompletionEvents(for: bookId)
        }
    }

    func updateLastRead(bookId: String, chapter: Int, verse: Int) {
        profile.lastRead[bookId] = ["chapter": chapter, "verse": verse]
        profile.lastReadBookId = bookId
        saveProfile()
    }

    func unmarkChapterRead(bookId: String, chapter: Int) {
        var set = Set(profile.chaptersRead[bookId] ?? [])
        if set.contains(chapter) {
            set.remove(chapter)
            profile.chaptersRead[bookId] = Array(set).sorted()
            saveProfile()
        }
    }

    func setReadingPlan(_ plan: ReadingPlan) {
        profile.readingPlan = plan
        saveProfile()
    }

    /// Remove the user's reading plan entirely.
    func deleteReadingPlan() {
        profile.readingPlan = nil
        saveProfile()
    }

    func addBookmark(_ verseId: String) {
        if !profile.bookmarks.contains(verseId) {
            profile.bookmarks.append(verseId)
            saveProfile()
        }
    }

    func removeBookmark(_ verseId: String) {
        if let idx = profile.bookmarks.firstIndex(of: verseId) {
            profile.bookmarks.remove(at: idx)
            saveProfile()
        }
    }

    func isBookmarked(_ verseId: String) -> Bool {
        profile.bookmarks.contains(verseId)
    }

    // MARK: - Notes
    func chapterNote(for chapterId: String) -> String? {
        profile.chapterNotes[chapterId]
    }

    func verseNote(for chapterId: String, verse: Int) -> String? {
        profile.verseNotes[chapterId]?["\(verse)"]
    }

    func setChapterNote(_ text: String, chapterId: String) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            profile.chapterNotes.removeValue(forKey: chapterId)
        } else {
            profile.chapterNotes[chapterId] = text
        }
        saveProfile()
    }

    func setVerseNote(_ text: String, chapterId: String, verse: Int) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            profile.verseNotes[chapterId]?["\(verse)"] = nil
            if profile.verseNotes[chapterId]?.isEmpty ?? false {
                profile.verseNotes.removeValue(forKey: chapterId)
            }
        } else {
            var notes = profile.verseNotes[chapterId] ?? [:]
            notes["\(verse)"] = text
            profile.verseNotes[chapterId] = notes
        }
        saveProfile()
    }

    // MARK: - Settings
    func updateBibleId(_ id: String) {
        profile.bibleId = id
        saveProfile()
    }

    func updateFontSize(_ size: FontSizeOption) {
        profile.fontSize = size
        saveProfile()
    }

    func updateFontChoice(_ choice: FontChoice) {
        profile.fontChoice = choice
        saveProfile()
    }

    func updateVerseSpacing(_ spacing: VerseSpacingOption) {
        profile.verseSpacing = spacing
        saveProfile()
    }

    func updateTheme(_ theme: AppTheme) {
        profile.theme = theme
        saveProfile()
    }

    // MARK: - Celebration helpers
    /// Trigger manual celebration events for testing.
    func triggerChapterCelebration() {
        triggerCelebration(.chapter)
    }

    func triggerBookCelebration() {
        let progress = Double(profile.totalChaptersRead) / 1189.0
        triggerCelebration(.book(progress: progress))
    }

    func triggerBibleCelebration() {
        triggerCelebration(.bible)
    }

    private func triggerCelebration(_ event: CelebrationEvent) {
        celebrationEvent = event
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if self?.celebrationEvent != nil {
                self?.celebrationEvent = nil
            }
        }
    }

    private func triggerCompletionEvents(for bookId: String) {
        let chaptersRead = Set(profile.chaptersRead[bookId] ?? [])
        let totalChapters = chaptersCount(for: bookId)
        if chaptersRead.count == totalChapters {
            if profile.totalChaptersRead == 1189 {
                triggerCelebration(.bible)
            } else {
                let progress = Double(profile.totalChaptersRead) / 1189.0
                triggerCelebration(.book(progress: progress))
            }
        } else {
            triggerCelebration(.chapter)
        }
    }

    private func chaptersCount(for bookId: String) -> Int {
        (oldTestamentCategories + newTestamentCategories)
            .flatMap { $0.books }
            .first { $0.id == bookId }?.chapters ?? 0
    }
}
