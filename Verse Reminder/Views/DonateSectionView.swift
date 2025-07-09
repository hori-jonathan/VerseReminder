import SwiftUI

struct DonateSectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("If you have enjoyed or received value from this app, consider supporting my projects here:")
            Link("buymeacoffee.com/jonathanhori", destination: URL(string: "https://buymeacoffee.com/jonathanhori")!)
                .foregroundColor(.blue)
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.top)
    }
}

struct DonateSectionView_Previews: PreviewProvider {
    static var previews: some View {
        DonateSectionView()
    }
}

