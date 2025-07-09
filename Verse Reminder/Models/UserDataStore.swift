import Foundation
import FirebaseFirestore

class UserDataStore {
    private let db = Firestore.firestore()

    func saveProfile(_ profile: UserProfile, uid: String, completion: ((Error?) -> Void)? = nil) {
        db.collection("users").document(uid).setData(profile.dictionary, merge: true) { error in
            completion?(error)
        }
    }

    func loadProfile(uid: String, completion: @escaping (UserProfile?, Error?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(), let profile = UserProfile(dict: data) {
                completion(profile, nil)
            } else {
                completion(nil, error)
            }
        }
    }

    func deleteProfile(uid: String, completion: ((Error?) -> Void)? = nil) {
        db.collection("users").document(uid).delete { error in
            completion?(error)
        }
    }
}
