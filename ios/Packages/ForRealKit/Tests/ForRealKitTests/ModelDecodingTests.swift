import Testing
import Foundation
@testable import ForRealKit

@Suite("Fax model decoding")
struct ModelDecodingTests {

    @Test("decodes a complete done fax with three claims")
    func decodesCompleteDoneFax() throws {
        let json = """
        {
            "id": "fax-1",
            "source_url": "https://www.youtube.com/watch?v=abc",
            "source_type": "video",
            "source_provider": "youtube",
            "title": null,
            "status": "done",
            "final_verdict": "nope",
            "final_commentary": "Bestie no.",
            "error_code": null,
            "created_at": 1700000000,
            "finished_at": 1700000060,
            "claims": [
                {
                    "position": 1,
                    "claim_text": "first",
                    "verdict": "nope",
                    "commentary": "no",
                    "sources": [{"url": "https://s1", "title": "s1"}],
                    "resolved_at": 1700000020
                },
                {
                    "position": 2,
                    "claim_text": "second",
                    "verdict": "mixed",
                    "commentary": "meh",
                    "sources": [],
                    "resolved_at": 1700000030
                },
                {
                    "position": 3,
                    "claim_text": "third",
                    "verdict": "yep",
                    "commentary": "yep",
                    "sources": [{"url": "https://s3", "title": "s3"}],
                    "resolved_at": 1700000040
                }
            ]
        }
        """.data(using: .utf8)!

        let fax = try JSONDecoder().decode(Fax.self, from: json)

        #expect(fax.id == "fax-1")
        #expect(fax.sourceProvider == .youtube)
        #expect(fax.status == .done)
        #expect(fax.finalVerdict == .nope)
        #expect(fax.claims.count == 3)
        #expect(fax.claims[0].verdict == .nope)
        #expect(fax.claims[0].sources.first?.url == "https://s1")
    }

    @Test("decodes a pending fax with empty claims")
    func decodesPendingFax() throws {
        let json = """
        {
            "id": "fax-2",
            "source_url": "https://tiktok.com/x",
            "source_type": "video",
            "source_provider": "tiktok",
            "title": null,
            "status": "pending",
            "final_verdict": null,
            "final_commentary": null,
            "error_code": null,
            "created_at": 1700000000,
            "finished_at": null,
            "claims": []
        }
        """.data(using: .utf8)!

        let fax = try JSONDecoder().decode(Fax.self, from: json)
        #expect(fax.status == .pending)
        #expect(fax.finalVerdict == nil)
        #expect(fax.claims.isEmpty)
    }

    @Test("Verdict glyphs are stable")
    func verdictGlyphsAreStable() {
        #expect(Verdict.nope.glyph == "❌")
        #expect(Verdict.mixed.glyph == "🤷")
        #expect(Verdict.yep.glyph == "✅")
        #expect(Verdict.skip.glyph == "🤔")
    }
}
