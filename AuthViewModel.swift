import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = true
    @Published var error: Error?

    private var listener: AuthStateDidChangeListenerHandle?
    private let dataStore = UserDataStore()

    init() {
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
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
            Auth.auth().signInAnonymously { [weak self] result, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.error = error
                    } else {
                        self?.user = result?.user
                    }
                }
            }
        } else {
            self.user = Auth.auth().currentUser
            self.isLoading = false
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

    func saveProgress(_ progress: [String: Any]) {
        guard let uid = user?.uid else { return }
        dataStore.saveProgress(progress, uid: uid, completion: nil)
    }
}
