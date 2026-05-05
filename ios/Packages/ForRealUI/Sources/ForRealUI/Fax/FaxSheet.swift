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
    public let onRetry: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reducedMotion

    public init(state: State, onRetry: @escaping () -> Void = {}) {
        self.state = state
        self.onRetry = onRetry
    }

    public var body: some View {
        ZStack {
            Color.zestyLemon.ignoresSafeArea()
            switch state {
            case .skip(let commentary):
                FaxSkipState(commentary: commentary)
            case .failed(let errorCode):
                FaxErrorState(errorCode: errorCode, onRetry: onRetry)
            default:
                defaultBody
            }
        }
        .animation(
            reducedMotion ? ForRealMotion.reduceMotionHighlight.curve : ForRealMotion.claimArrival.curve,
            value: animationKey
        )
    }

    private var defaultBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VerdictHeader(verdict: currentVerdict)
                if let commentary = currentCommentary {
                    Text(commentary)
                        .font(ForRealType.headline.weight(.regular))
                        .foregroundStyle(Color.lemonCharcoal)
                }
                ForEach(1...3, id: \.self) { i in
                    ClaimCard(position: i, claim: claim(at: i))
                }
                if case .final(let verdict, let commentary, let claims) = state {
                    FaxShareButton(verdict: verdict, commentary: commentary, claims: claims)
                        .padding(.top, 8)
                }
            }
            .padding(24)
        }
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
