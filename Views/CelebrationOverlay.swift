import SwiftUI

/// Celebration events triggered by reading progress.
enum CelebrationEvent: Equatable {
  case chapter
  case book(progress: Double)
  case bible
}

/// Overlay that displays progress indicators when events fire.
struct CelebrationOverlay: View {
  let event: CelebrationEvent?
  @Environment(\.colorScheme) private var scheme
  @State private var show = false
  @State private var currentEvent: CelebrationEvent?

  private var fadeColor: Color {
    scheme == .dark ? .black : .white
  }

  var body: some View {
    if let active = currentEvent {
      ZStack {
        fadeColor.opacity(0.6)
          .ignoresSafeArea()
          .transition(.opacity)
        VStack {
          if case .book(let progress) = active {
            CelebrationProgress(progress: progress)
              .padding(.top, 50)
            Spacer()
          } else if case .bible = active {
            CelebrationProgress(progress: 1)
              .padding(.top, 50)
            Spacer()
          } else if case .chapter = active {
            ChapterProgressBar()
              .padding(.top, 50)
            Spacer()
          } else {
            Spacer()
          }
          Text("Keep studying and thank you for using our app!")
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(.top, 20)
        }
      }
      .transition(.opacity)
      .animation(.easeInOut(duration: 0.35), value: show)
      .opacity(show ? 1 : 0)
      .onAppear {
        currentEvent = event
        withAnimation(.easeInOut(duration: 0.35)) { show = true }
      }
      .onChange(of: event) { newValue in
        if let new = newValue {
          currentEvent = new
          withAnimation(.easeInOut(duration: 0.35)) { show = true }
        } else {
          withAnimation(.easeInOut(duration: 0.35)) { show = false }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if event == nil {
              currentEvent = nil
            }
          }
        }
      }
    }
  }
}

/// Simple progress bar used for book and bible completion.
struct CelebrationProgress: View {
  let progress: Double
  var body: some View {
    VStack(spacing: 8) {
      Text(String(format: "%.0f%% Complete", progress * 100))
        .foregroundColor(Color.accentColor)
        .font(.headline)
      ProgressView(value: progress)
        .progressViewStyle(LinearProgressViewStyle())
        .tint(Color.accentColor)
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
      .progressViewStyle(LinearProgressViewStyle(tint: Color.accentColor))
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
