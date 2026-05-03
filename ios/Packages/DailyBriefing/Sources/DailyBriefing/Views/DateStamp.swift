// MARK: - DateStamp
//
// "MAY 03 · 2026" mono ink, slammed into the top-right corner at -6°, with a
// thin border evoking a real ink-pad rectangle.
//
// Per the 2026-05-03 brief §8 Content Requirements:
//   "Date stamp — mono, MAY 03 · 2026, slammed into top-right at ~−6°, ink-bleed."
//
// And §6 First-of-day cold launch:
//   "date stamp StampSlam into the corner, then 10 PinDrops in sequence with
//    a ~80ms stagger."
//
// This component is the *static* date-stamp visual; the StampSlam staging
// wraps it on first-per-day cold launch. In-place renders use this view alone.

import SwiftUI
import DesignSystem

public struct DateStamp: View {
    let date: Date
    let calendar: Calendar

    public init(date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.date = date
        self.calendar = calendar
    }

    public var body: some View {
        Text(formatted)
            .font(.fileTitle)
            .tracking(1.4)
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(Color.ink, lineWidth: 1.5)
            )
            .background(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.ink.opacity(0.05))
            )
            .rotationEffect(.degrees(-6))
            .accessibilityElement()
            .accessibilityLabel(Text("Date stamp: \(longFormatted)"))
    }

    private var formatted: String {
        let comps = calendar.dateComponents([.month, .day, .year], from: date)
        let month = monthShort(comps.month ?? 1)
        let day = String(format: "%02d", comps.day ?? 1)
        let year = String(comps.year ?? 2026)
        return "\(month) \(day) · \(year)"
    }

    private var longFormatted: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private func monthShort(_ m: Int) -> String {
        let months = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"]
        let idx = max(1, min(12, m)) - 1
        return months[idx]
    }
}
