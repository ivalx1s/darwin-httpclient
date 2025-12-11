import Foundation
import Security
import Testing
@testable import HttpClient

@Suite struct SSLPinningTests {
    private let pinnedCertBase64 = "MIICqDCCAZACCQCSdosY+Hs6eTANBgkqhkiG9w0BAQsFADAWMRQwEgYDVQQDDAtleGFtcGxlLmNvbTAeFw0yNTEyMTExNDU2MTJaFw0yNTEyMTIxNDU2MTJaMBYxFDASBgNVBAMMC2V4YW1wbGUuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxkp6ix2P5ZvYLNy04uw+O0AgzX2C609QYKzjH+LwK0glV5l1QJ2YpfPb4tvaJEFKPWTj/+jtJv36yRKV9YUqQZhuxIaeC5USDC5MUTTrbKE4Snj//KfUSk8j3SdkGkO8qTPq4YA4v+uvV/xaA+GUB1j2RMartMEgCCxCGkw6ysV2RJCa4Db+BTT1JgZrTgWOh+e+Dud4O8RhJTjusOFXHc+hfEjHE5tAg6JOCBjxs476o5/bJZZjDna6InHk/GO0ZaMl7vMUeJTOHONBJcOSjgwsUv89IccJH7+RPmtPE4QdBP3VAKk5Wv/hqD5/72W6UNwb3AK/oKD1qnrVgP4iewIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQAtugIysJSRsLnJoDfc0pq9KlkgWcpExtagPOjp1jDguRDwnl8BR6JMtX/jGelA8clOWk2vEFBqSB3JVPtiVVdP47eI9UXC79/a+d3RxzjN8FfclJC8DYZ4SXnUc6QKVZTc8zhwykVCMC5TpZKmxiSZAf5qfNR10z1f70cTk/qS50k1cMCB1G8SWm+YCJnZITc81vQP2S87/5vk4XOEP6Q68HCHaSWLrVj67032NsTqruRwXY/UcrP1HLjxliJWmEhnAJOPumxhTAQfu2OKefwZCuUOTg3HqqfP0DTxbW1jmxeeLUn4M1me2rnZJeyxzMX9byDWxVaWLShnRnYXUmni"
    private let otherCertBase64 = "MIICpDCCAYwCCQCNYtoQcV2c0jANBgkqhkiG9w0BAQsFADAUMRIwEAYDVQQDDAlvdGhlci5jb20wHhcNMjUxMjExMTQ1ODE0WhcNMjUxMjEyMTQ1ODE0WjAUMRIwEAYDVQQDDAlvdGhlci5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDSTWz3cEYLWFvUFXyM9p5Gqo5dOJ3owDHYRG5t9aEpTeWpNnPPNcyDOBrpm52SwiAA3uxiQSvT/3mzzw8B7292cuUf0qP645ZgxHtkhNEeARyxrmJMCxineksysbGn8NXuu4xxJWn/2v70UDYW7IitmDXkyMipoZ43dcUoFz6xAi5N9nUv8ejTR0jNdDoOpnkxUxgek87+NWtTpSl/Sq1t61mqLKKqZrz9Kpj+JUN6wsp4zt86IWai2xrqom+2DDpqYvom/SeXLOPdlW2EGBzIc+t/ljWKB2vomdasW/gSNXaRYXf4/sjqOHUr25W1CqSaEk49549rRUzzlMChff6tAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAC7s18xvsVq73XUAwYfH6sKgov/W+8Yn4n/NABZJhhzw9yG7jW6OMr91JrZTdDq4LzPtpu4xljNaL58gzXsxwdODS3v2S96XRqbtFWb2HdvxBX8cgJkAujYJGvE+wNe83dB39FSvXEN/4xZhX3+kyWX4L3hUJYKgmvzPs2VKvpcrMyU8PJ5c6aymRWYvsMRQU8T4RYGprS81/q+e7qX/o5+t0XEGv2DPuhloADb8oUgc7PbLqNAbSGS8qwgVZEfS5kvMR65iCNQQPQnWw/yM7jfgYFgydEpoW3EffZFXMbYxI1x0o80+KYfIU0ExWr3okU4fd7zi2vnQX1jv5r1+RKI="

    @Test func certificateValidationPassesWhenPinnedCertMatches() async throws {
        guard #available(macOS 12.0, iOS 15.0, *) else { return }
        let pinnedCertUrl = try writeTemporaryCert(data: try decodeBase64(pinnedCertBase64))
        let trust = try makeTrust(from: try decodeBase64(pinnedCertBase64), hostname: "example.com")

        let challenge = CertVerificationChallenge(
            certUrls: [pinnedCertUrl],
            validationStrategy: .anyCertFromChain,
            logger: TestLogger()
        )

        let recorder = ChallengeRecorder()
        challenge.urlSession(
            URLSession.shared,
            didReceive: makeChallenge(trust: trust),
            completionHandler: recorder.handle
        )

        #expect(recorder.disposition == .useCredential)
        #expect(recorder.credential != nil)
    }

    @Test func certificateValidationCancelsWhenPinsDoNotMatch() async throws {
        guard #available(macOS 12.0, iOS 15.0, *) else { return }
        let pinnedCertUrl = try writeTemporaryCert(data: try decodeBase64(pinnedCertBase64))
        let unpinnedTrust = try makeTrust(from: try decodeBase64(otherCertBase64), hostname: "other.com")

        let challenge = CertVerificationChallenge(
            certUrls: [pinnedCertUrl],
            validationStrategy: .allCertsFromChain,
            logger: TestLogger()
        )

        let recorder = ChallengeRecorder()
        challenge.urlSession(
            URLSession.shared,
            didReceive: makeChallenge(trust: unpinnedTrust),
            completionHandler: recorder.handle
        )

        #expect(recorder.disposition == .cancelAuthenticationChallenge)
    }

    @Test func publicKeyValidationUsesPinnedKey() async throws {
        guard #available(macOS 12.0, iOS 15.0, *) else { return }
        let pinnedCertUrl = try writeTemporaryCert(data: try decodeBase64(pinnedCertBase64))
        let trust = try makeTrust(from: try decodeBase64(pinnedCertBase64), hostname: "example.com")

        let challenge = CertPublicKeyVerificationChallenge(
            certUrls: [pinnedCertUrl],
            validationStrategy: .anyCertFromChain,
            logger: TestLogger()
        )

        let recorder = ChallengeRecorder()
        challenge.urlSession(
            URLSession.shared,
            didReceive: makeChallenge(trust: trust),
            completionHandler: recorder.handle
        )

        #expect(recorder.disposition == .useCredential)
    }

    @Test func challengeCancelsWhenTrustMissing() {
        let challenge = CertVerificationChallenge(
            certUrls: [],
            validationStrategy: .anyCertFromChain,
            logger: TestLogger()
        )

        let recorder = ChallengeRecorder()
        challenge.urlSession(
            URLSession.shared,
            didReceive: makeChallenge(trust: nil),
            completionHandler: recorder.handle
        )

        #expect(recorder.disposition == .cancelAuthenticationChallenge)
    }
}

private func decodeBase64(_ string: String) throws -> Data {
    try #require(Data(base64Encoded: string))
}

@available(macOS 12.0, iOS 15.0, *)
private func makeTrust(from certificateData: Data, hostname: String) throws -> SecTrust {
    let policy = SecPolicyCreateSSL(true, hostname as CFString)
    var trust: SecTrust?
    let certificate = try #require(SecCertificateCreateWithData(nil, certificateData as CFData))
    let status = SecTrustCreateWithCertificates(certificate, policy, &trust)
    #expect(status == errSecSuccess)
    return try #require(trust)
}

private func writeTemporaryCert(data: Data) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("cer")
    try data.write(to: url)
    return url
}

private final class ChallengeRecorder {
    private(set) var disposition: URLSession.AuthChallengeDisposition?
    private(set) var credential: URLCredential?

    func handle(_ disposition: URLSession.AuthChallengeDisposition, _ credential: URLCredential?) {
        self.disposition = disposition
        self.credential = credential
    }
}

private final class StubProtectionSpace: URLProtectionSpace, @unchecked Sendable {
    private let customTrust: SecTrust?

    init(trust: SecTrust?) {
        self.customTrust = trust
        super.init(host: "example.com", port: 443, protocol: "https", realm: nil, authenticationMethod: NSURLAuthenticationMethodServerTrust)
    }

    override var serverTrust: SecTrust? { customTrust }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class DummyChallengeSender: NSObject, URLAuthenticationChallengeSender, @unchecked Sendable {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    func cancel(_ challenge: URLAuthenticationChallenge) {}
}

private func makeChallenge(trust: SecTrust?) -> URLAuthenticationChallenge {
    URLAuthenticationChallenge(
        protectionSpace: StubProtectionSpace(trust: trust),
        proposedCredential: nil,
        previousFailureCount: 0,
        failureResponse: nil,
        error: nil,
        sender: DummyChallengeSender()
    )
}
