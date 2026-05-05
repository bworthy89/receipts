#if os(iOS)
import SwiftUI
import ForRealKit

public struct FaxSheet: View {

    public enum State: Equatable {
        case initial
        case streaming(partial: [Claim], finalVerdict: Verdict?, finalCommentary: String?)
        case final(verdict: Verdict, commentary: String, claims: [Claim])
        case skip(commentary: String)
        case failed(errorCode: String)
    }

    public let state: State

    @Environment(\.accessibilityReduceMotion) private var reducedMotion

    public init(state: State) { self.state = state }

    public var body: some View {
        ZStack {
            Color.zestyLemon.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VerdictHeader(verdict: currentVerdict)
                    if let commentary = currentCommentary {
                        Text(commentary)
                            .font(ForRealType.headline.weight(.regular))
                            .foregroundStyle(Color.lemonCharcoal)
                    }
                    if !isSkip {
                        ForEach(1...3, id: \.self) { i in
                            ClaimCard(position: i, claim: claim(at: i))
                        }
                    }
                }
                .padding(24)
            }
        }
        .animation(
            reducedMotion ? ForRealMotion.reduceMotionHighlight.curve : ForRealMotion.claimArrival.curve,
            value: animationKey
        )
    }

    // MARK: - Animation key

    private var animationKey: String {
        switch state {
        case .initial:                                      "initial"
        case .streaming(let partial, let v, _):             "streaming-claims-\(partial.count)-verdict-\(v?.rawValue ?? "nil")"
        case .final(let v, _, let claims):                  "final-\(v.rawValue)-claims-\(claims.count)"
        case .skip:                                         "skip"
        case .failed(let code):                             "failed-\(code)"
        }
    }

    // MARK: - Derived

    private var currentVerdict: Verdict? {
        switch state {
        case .initial:                                  nil
        case .streaming(_, let verdict, _):             verdict
        case .final(let verdict, _, _):                 verdict
        case .skip:                                     .skip
        case .failed:                                   nil
        }
    }

    private var currentCommentary: String? {
        switch state {
        case .initial:                                  nil
        case .streaming(_, _, let commentary):          commentary
        case .final(_, let commentary, _):              commentary
        case .skip(let commentary):                     commentary
        case .failed:                                   nil
        }
    }

    private var isSkip: Bool {
        if case .skip = state { return true }
        return false
    }

    private func claim(at position: Int) -> Claim? {
        switch state {
        case .initial:                                       return nil
        case .streaming(let partial, _, _):                  return partial.first(where: { $0.position == position })
        case .final(_, _, let claims):                       return claims.first(where: { $0.position == position })
        case .skip, .failed:                                 return nil
        }
    }
}

// MARK: - Coordinator adapter

public extension FaxSheet.State {
    /// Derives the view-side state from a coordinator's runtime state.
    static func from(_ coordState: ReceiptCoordinator.State) -> FaxSheet.State {
        switch coordState {
        case .idle:
            return .initial
        case .streaming(_, let partial, let final):
            return .streaming(partial: partial, finalVerdict: final?.verdict, finalCommentary: final?.commentary)
        case .final(let fax):
            if fax.finalVerdict == .skip {
                return .skip(commentary: fax.finalCommentary ?? "")
            }
            return .final(verdict: fax.finalVerdict ?? .mixed, commentary: fax.finalCommentary ?? "", claims: fax.claims)
        case .failed(let code):
            return .failed(errorCode: code)
        }
    }
}
#endif
