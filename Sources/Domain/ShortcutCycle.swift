import Foundation

public enum ShortcutCycle {
    public struct Group: Hashable, Sendable {
        public var chord: KeyChord
        public var actions: [WindowAction]

        public init(chord: KeyChord, actions: [WindowAction]) {
            self.chord = chord
            self.actions = actions
        }

        public var isCycle: Bool { actions.count > 1 }
    }

    public static func groups(from shortcuts: [WindowAction: KeyChord]) -> [Group] {
        var buckets: [KeyChord: [WindowAction]] = [:]
        for action in WindowAction.allCases {
            guard let chord = shortcuts[action] else { continue }
            buckets[chord, default: []].append(action)
        }
        return buckets.map { Group(chord: $0.key, actions: $0.value) }
    }

    public static func next(after last: WindowAction?, in actions: [WindowAction]) -> WindowAction {
        guard !actions.isEmpty else { return .maximize }
        guard let last, let index = actions.firstIndex(of: last) else {
            return actions[0]
        }
        return actions[(index + 1) % actions.count]
    }
}
