import Foundation

extension String {
    func levenshteinDistance(to target: String) -> Int {
        let source = Array(self.lowercased())
        let target = Array(target.lowercased())
        let (m, n) = (source.count, target.count)
        var dist = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 0...m { dist[i][0] = i }
        for j in 0...n { dist[0][j] = j }
        for i in 1...m {
            for j in 1...n {
                if source[i-1] == target[j-1] {
                    dist[i][j] = dist[i-1][j-1]
                } else {
                    dist[i][j] = Swift.min(dist[i-1][j-1], dist[i-1][j], dist[i][j-1]) + 1
                }
            }
        }
        return dist[m][n]
    }

    func similarityScore(to target: String) -> Double {
        if self.isEmpty && target.isEmpty { return 1 }
        let distance = self.levenshteinDistance(to: target)
        return 1 - Double(distance) / Double(max(self.count, target.count))
    }

    /// Removes a leading paragraph symbol if present.
    func trimmingLeadingParagraphSymbol() -> String {
        if self.hasPrefix("\u{00B6}") {
            return String(self.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return self
    }
}
