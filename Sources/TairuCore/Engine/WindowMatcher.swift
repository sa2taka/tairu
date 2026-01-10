public enum WindowMatcher {
    public static func findMatches(for rule: WindowRule, in windows: [WindowSnapshot]) -> [WindowSnapshot] {
        var candidates = windows.filter { $0.appBundleId == rule.appBundleId }

        if let titleMatch = rule.titleMatch {
            candidates = candidates.filter { titleMatch.matches($0.title) }
        }

        if let indexHint = rule.indexHint {
            guard indexHint >= 0, indexHint < candidates.count else {
                return []
            }
            return [candidates[indexHint]]
        }

        return candidates
    }
}
