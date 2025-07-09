import SwiftUI

struct ContactView: View {
    @State private var email = ""
    @State private var name = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var resultMessage: String?

    var body: some View {
        Form {
            Section(header: Text("Your Info")) {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            Section(header: Text("Message")) {
                TextEditor(text: $message)
                    .frame(minHeight: 150)
            }
            Section {
                if let result = resultMessage {
                    Text(result)
                        .foregroundColor(.secondary)
                }
                Button(action: submit) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("Send")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isSubmitting || email.isEmpty || message.isEmpty)
            }
        }
        .navigationTitle("Contact Us")
    }

    private func submit() {
        isSubmitting = true
        ContactAPI.shared.submitMessage(email: email, name: name, message: message) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    resultMessage = "Thank you! Your message was sent."
                    email = ""
                    name = ""
                    message = ""
                case .failure:
                    resultMessage = "Failed to send message. Please try again later."
                }
            }
        }
    }
}
