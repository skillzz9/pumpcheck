import sys

with open("PumpCheck.swiftpm/Onboarding/StatsView.swift", "r") as f:
    content = f.read()

old_lift_parse = """                if let rawLifts = data["lifts"] as? [[String: Any]] {
                    parsedLifts = rawLifts.compactMap { ld -> LiftRecord? in
                        guard let ln = ld["name"] as? String, let lw = ld["weight"] as? Double else { return nil }
                        return LiftRecord(name: ln, weight: lw)
                    }
                }"""

new_lift_parse = """                if let rawLifts = data["lifts"] as? [[String: Any]] {
                    parsedLifts = rawLifts.compactMap { ld -> LiftRecord? in
                        guard let ln = ld["name"] as? String, let lw = ld["weight"] as? Double else { return nil }
                        let lr = ld["reps"] as? Int ?? 1
                        return LiftRecord(name: ln, weight: lw, reps: lr)
                    }
                }"""

content = content.replace(old_lift_parse, new_lift_parse)

with open("PumpCheck.swiftpm/Onboarding/StatsView.swift", "w") as f:
    f.write(content)

