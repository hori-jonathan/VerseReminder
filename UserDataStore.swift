import Foundation
import FirebaseFirestore

class UserDataStore {
    private let db = Firestore.firestore()

    func saveProgress(_ progress: [String: Any], uid: String, completion: ((Error?) -> Void)?) {
        db.collection("users").document(uid).setData(progress, merge: true) { error in
            completion?(error)
        }
    }

    func loadProgress(uid: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                completion(data, nil)
            } else {
                completion(nil, error)
            }
        }
    }
}
