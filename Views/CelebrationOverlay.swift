import SwiftUI

/// Celebration events triggered by reading progress.
enum CelebrationEvent {
  case chapter
  case book(progress: Double)
  case bible
}

/// Overlay that displays progress indicators when events fire.
struct CelebrationOverlay: View {
  let event: CelebrationEvent?
  var body: some View {
    if let event = event {
      ZStack {
        Color.clear.ignoresSafeArea()
        VStack {
          if case .book(let progress) = event {
            CelebrationProgress(progress: progress)
              .padding(.top, 50)
            Spacer()
          } else if case .bible = event {
            CelebrationProgress(progress: 1)
              .padding(.top, 50)
            Text("Congratulations! You've completed the Bible!")
              .font(.title)
              .fontWeight(.heavy)
              .foregroundColor(.yellow)
              .shadow(color: Color.yellow.opacity(0.7), radius: 6)
              .padding(.top, 8)
            Spacer()
          } else if case .chapter = event {
            ChapterProgressBar()
              .padding(.top, 50)
            Spacer()
          } else {
            Spacer()
          }
        }
      }
      .transition(.opacity)
    }
  }
}

/// Simple progress bar used for book and bible completion.
struct CelebrationProgress: View {
  let progress: Double
  private let gradient = LinearGradient(
    gradient: Gradient(colors: [Color.yellow, Color.orange]), startPoint: .leading,
    endPoint: .trailing)
  var body: some View {
    VStack(spacing: 8) {
      Text(String(format: "%.0f%% Complete", progress * 100))
        .foregroundColor(.yellow)
        .font(.headline)
      ProgressView(value: progress)
        .progressViewStyle(LinearProgressViewStyle(tint: gradient))
        .frame(width: 220)
    }
    .padding(12)
    .background(Color.black.opacity(0.7))
    .cornerRadius(12)
  }
}

/// Animated bar used when a single chapter is completed.
struct ChapterProgressBar: View {
  @State private var progress: Double = 0
  var body: some View {
    ProgressView(value: progress)
      .progressViewStyle(LinearProgressViewStyle(tint: .gray))
      .frame(width: 150)
      .onAppear {
        withAnimation(.easeOut(duration: 1.0)) {
          progress = 1
        }
      }
      .padding(12)
      .background(Color.black.opacity(0.6))
      .cornerRadius(12)
  }
}
