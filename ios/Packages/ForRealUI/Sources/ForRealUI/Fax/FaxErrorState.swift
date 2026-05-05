#if os(iOS)
import SwiftUI

public enum FaxErrorCopy {
    public static func message(for errorCode: String) -> String {
        switch errorCode {
        case "source_unreachable":   "Couldn't reach this one — link may be private or pulled."
        case "provider_blocked":     "TikTok's playing hard to get. Try again in a sec."
        case "transcription_failed": "Couldn't make out the audio."
        case "paywalled":            "Paywall blocked us — try a public mirror."
        case "unsupported_provider": "We don't speak that platform yet — coming later."
        default:                     "Something fell over. Try again?"
        }
    }
}

struct FaxErrorState: View {
    let errorCode: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("OOPS").forRealLabelStyle().foregroundStyle(Color.oliveAnchor)
            Text(FaxErrorCopy.message(for: errorCode))
                .font(ForRealType.headline)
                .foregroundStyle(Color.lemonCharcoal)
            Button(action: onRetry) {
                Text("Try again")
                    .font(ForRealType.body.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .foregroundStyle(Color.zestyLemon)
                    .background(Color.lemonCharcoal, in: RoundedRectangle(cornerRadius: 6))
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#else
// Non-iOS: FaxErrorCopy still available; FaxErrorState skipped.
public enum FaxErrorCopy {
    public static func message(for errorCode: String) -> String {
        switch errorCode {
        case "source_unreachable":   "Couldn't reach this one — link may be private or pulled."
        case "provider_blocked":     "TikTok's playing hard to get. Try again in a sec."
        case "transcription_failed": "Couldn't make out the audio."
        case "paywalled":            "Paywall blocked us — try a public mirror."
        case "unsupported_provider": "We don't speak that platform yet — coming later."
        default:                     "Something fell over. Try again?"
        }
    }
}
#endif
