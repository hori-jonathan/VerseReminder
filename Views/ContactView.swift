import SwiftUI

struct ContactView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 40))
                .padding(.bottom, 8)
            Text("Email us at")
            Link("support@example.com", destination: URL(string: "mailto:support@example.com")!)
                .foregroundColor(.blue)
        }
        .navigationTitle("Contact Us")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
