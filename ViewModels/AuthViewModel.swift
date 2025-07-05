import Foundation
import FirebaseAuth
import GoogleSignIn

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = true
    @Published var error: Error?
    @Published var profile = UserProfile()

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
        if !set.contains(chapter) {
            set.insert(chapter)
            profile.chaptersRead[bookId] = Array(set).sorted()
        }
        profile.lastRead[bookId] = ["chapter": chapter, "verse": verse]
        saveProfile()
    }

    func updateLastRead(bookId: String, chapter: Int, verse: Int) {
        profile.lastRead[bookId] = ["chapter": chapter, "verse": verse]
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
}
