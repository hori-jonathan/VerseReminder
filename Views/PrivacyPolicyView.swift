import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 40))
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)
                Text("Privacy Policy")
                    .font(.title2)
                Text("We respect your privacy and only store data necessary for your progress tracking.")
                Link("Read full policy", destination: URL(string: "https://example.com/privacy")!)
                    .foregroundColor(.blue)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Privacy Policy")
    }
}
