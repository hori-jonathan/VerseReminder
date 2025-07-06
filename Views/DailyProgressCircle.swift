import SwiftUI

struct DailyProgressCircle: View {
    var progress: Double
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 12)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1)))
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]), center: .center),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.green.opacity(0.7), radius: 6)
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .bold()
        }
        .frame(width: 80, height: 80)
    }
}

struct DailyProgressCircle_Previews: PreviewProvider {
    static var previews: some View {
        DailyProgressCircle(progress: 0.4)
    }
}
