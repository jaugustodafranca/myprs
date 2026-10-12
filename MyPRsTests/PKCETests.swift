@testable import MyPRs
import Testing

struct PKCETests {
    @Test func derivesChallengeFromRFC7636Example() {
        let challenge = PKCE.challenge(for: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        #expect(challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    @Test func randomVerifierIsUnpadded43CharacterBase64URL() {
        let verifier = PKCE.random().verifier
        #expect(verifier.count == 43)
        #expect(verifier.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") })
    }

    @Test func randomVerifiersDiffer() {
        #expect(PKCE.random().verifier != PKCE.random().verifier)
    }
}
