import SwiftUI
import UIKit

/// Celebration events triggered by reading progress.
enum CelebrationEvent {
    case chapter
    case book(progress: Double)
    case bible
}

/// UIKit based confetti view using CAEmitterLayer so it works without third party dependencies.
struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 2)
        emitter.beginTime = CACurrentMediaTime()
        emitter.timeOffset = 0
        emitter.emitterCells = (0..<12).map { _ in
            let cell = CAEmitterCell()
            cell.birthRate = 4
            cell.lifetime = 6.0
            cell.velocity = 150
            cell.velocityRange = 50
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spinRange = 4
            cell.scale = 0.6
            cell.scaleRange = 0.3
            cell.color = UIColor(hue: CGFloat.random(in: 0...1), saturation: 0.9, brightness: 1, alpha: 1).cgColor
            cell.contents = UIImage(systemName: "circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal).cgImage
            return cell
        }
        view.layer.addSublayer(emitter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            emitter.birthRate = 0
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

/// Overlay that displays confetti and optional progress bar when events fire.
struct CelebrationOverlay: View {
    let event: CelebrationEvent?
    var body: some View {
        if let event = event {
            ZStack {
                ConfettiView()
                    .ignoresSafeArea()
                VStack {
                    if case .book(let progress) = event {
                        CelebrationProgress(progress: progress)
                            .padding(.top, 50)
                        Spacer()
                    } else if case .bible = event {
                        CelebrationProgress(progress: 1)
                            .padding(.top, 50)
                        Text("Congratulations! You've completed the Bible!")
                            .font(.headline)
                            .padding(.top, 8)
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
    var body: some View {
        VStack(spacing: 8) {
            Text(String(format: "%.0f%% Complete", progress * 100))
                .foregroundColor(.white)
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .frame(width: 220)
        }
        .padding(12)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
}

