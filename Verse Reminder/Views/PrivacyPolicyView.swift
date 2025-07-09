import SwiftUI

struct PrivacyPolicyView: View {
    private let policyBody = """
This Privacy Policy explains how VerseReminder (“the App”), developed by Jonathan Hori (“we,” “us,” “our”), collects, uses, and protects your information. The App provides Bible reading features, progress tracking, and optional account sign-in. This policy is designed to comply with Section 5.1 of Apple’s App Store Review Guidelines.

1. Data We Collect

Account and Authentication Data
When you first launch the App, you are automatically signed in anonymously using Firebase Authentication. Your progress is stored in Firebase Firestore under your anonymous user ID. If you link a Google or email account, your email address is also stored in Firebase.
Firebase generates a unique identifier for your account and may collect device identifiers and IP address as part of its service.

User Profile and Reading Progress
We store your reading progress, bookmarks, notes, reading plans, daily chapter counts, and personalization settings (such as Bible version, font size, theme, and notification times). These are saved to Firestore whenever you read or modify content.

Contact Information
If you send feedback through the in-app “Contact Us” form, the App collects your name, email address, message content, and a timestamp. This information is transmitted via HTTPS to our self-hosted service at https://usa-chat.com and stored in a secure database. This information is used only to respond to your inquiry and is never used for marketing.

Verse and Content Requests
When you read or search for verses, the App requests verse data from our self-hosted Bible API at https://usa-chat.com. These requests include the verse ID and selected Bible translation but do not include personal identifiers.

Notifications
If you enable reading reminders, the App requests permission to send local notifications. Notification schedules are stored in your profile and processed on your device.

Device Data
We do not collect GPS location, contacts, photos, or other device data. Firebase and Apple may log basic device information (such as device type, operating system version, and IP address) as part of their standard service operations.

Children’s Data
The App is not directed to children under the age of 13. We do not knowingly collect personal information from children under 13. If we learn we have received such information, we will delete it promptly.

2. How We Use Your Data

Provide Core Features: To deliver personalized content, track completion, and schedule reminders based on your progress, notes, and settings.
Account Management: Firebase Authentication manages sign-in and optional account linking.
Customer Support: Information submitted through the contact form allows us to respond to your inquiries or feedback.
No Advertising or Analytics: The App does not include advertising networks or third-party analytics SDKs, and we do not profile users for advertising.

3. Data Sharing

We do not sell or rent your data. We share information only with the following service providers:

Service    Purpose    Data Shared
Firebase Authentication & Firestore (Google LLC)    Account sign-in, cloud storage of reading progress and settings    Anonymous user ID, optional linked email, progress data, reading plans, bookmarks, notes
Google Sign-In (Google LLC)    Optional account linking with Google    Google ID token and access token during sign-in
Self-Hosted Bible API (usa-chat.com)    Provides verse content    Verse reference and Bible translation ID. No personal identifiers sent
Self-Hosted Contact API (usa-chat.com)    Stores feedback messages    Name, email address, message text, timestamp
Apple (UserNotifications)    Delivers local notifications if enabled    Notification schedule stored on device
All transmissions use HTTPS encryption.

4. Data Retention

User Profile Data: Stored in Firestore until you choose to reset or delete your account within the App. Resetting removes local data; deleting your account permanently removes your profile from Firestore.
Contact Messages: Retained on our server only as long as necessary to provide support.
Local Device Data: Settings and cached verses remain on your device until the App is uninstalled or the account is reset.

5. Your Rights and Choices

Access and Update: You can view and modify your reading progress, notes, and settings within the App.
Delete: Use the “Reset Account” or “Delete Account” options in the App’s advanced settings to remove your data. Deleting your account removes it from our servers.
Privacy Requests: For additional requests, you may send a message via the in-app contact form. At this time, privacy requests are handled exclusively through this form.
Your Rights: Users in the European Union (GDPR) and California (CCPA) may have additional rights to access, correct, or delete personal data. We honor these rights upon verified request.

6. Security Measures

All data is transmitted securely over HTTPS.
Firebase data is protected by Google’s security practices.
Access to our self-hosted servers is restricted and protected by authentication.
Despite these measures, no method of transmission or storage is 100% secure. We strive to protect your information but cannot guarantee absolute security.

7. International Transfers

Our servers and Firebase services are located in the United States. By using the App, you consent to the transfer of information to the United States and to other locations where our service providers operate.

8. Changes to This Policy

We may update this Privacy Policy from time to time. Significant changes will be announced within the App. Continued use of the App after changes are posted constitutes acceptance of the updated policy.

9. Contact Us

For privacy questions or requests, please use the in-app “Contact Us” form, which sends your message securely to our server at https://usa-chat.com. If you believe we have inadvertently collected information from a child under 13, please contact us via the form so we can remove it.
"""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 40))
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)
                Text("VerseReminder Privacy Policy")
                    .font(.title2)
                Text("Last updated: July 8, 2025")
                    .font(.subheadline)
                Text(policyBody)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Privacy Policy")
    }
}
