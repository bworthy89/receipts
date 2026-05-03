import Testing
@testable import DeepCheck

@Suite("Outlet appearance count")
struct OutletAppearanceTests {

    /// Reuters / AP / BBC are mock-canned to appear in every one of the 10
    /// briefing cases. This count drives the SourceDossierSheet caption
    /// "APPEARS IN N OF 10 ACTIVE CASES.", so a regression in either the
    /// data or the count walker should fail loudly.
    @Test("Reuters / AP / BBC appear in all 10 cases")
    func wireServicesAppearEverywhere() {
        #expect(MockProvider.outletAppearanceCount("Reuters") == 10)
        #expect(MockProvider.outletAppearanceCount("AP") == 10)
        #expect(MockProvider.outletAppearanceCount("BBC") == 10)
    }

    /// Specialist outlets appear in a handful of cases, exercising the
    /// "appears in N of 10" phrasing for non-trivial values.
    @Test("Specialist outlets appear in a handful of cases")
    func specialistsHaveLowCounts() {
        #expect(MockProvider.outletAppearanceCount("NPR") >= 1)
        #expect(MockProvider.outletAppearanceCount("KQED") >= 1)
        #expect(MockProvider.outletAppearanceCount("Ars Technica") >= 1)
    }

    /// Unknown outlets return 0 — the dossier caption renders correctly
    /// for "appears in 0 of 10" without crashing or erroring.
    @Test("Unknown outlet returns zero")
    func unknownReturnsZero() {
        #expect(MockProvider.outletAppearanceCount("Not An Outlet") == 0)
        #expect(MockProvider.outletAppearanceCount("") == 0)
    }

    /// Total denominator matches the canned table size — drives the
    /// "of N" half of the caption.
    @Test("caseCount denominator equals 10 in v1 mock")
    func caseCountIsTen() {
        #expect(MockProvider.caseCount == 10)
    }
}
