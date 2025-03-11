import Foundation

public protocol ICertVerificationChallenge: URLSessionDelegate {}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension CertVerificationChallenge {
    public enum ValidationStrategy {
        case anyCertFromChain
        case allCertsFromChain
    }
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
open class CertVerificationChallenge: NSObject, ICertVerificationChallenge, @unchecked Sendable {
    let certUrls: [URL]
    let validationStrategy: ValidationStrategy

    public init(
        certUrls: [URL],
        validationStrategy: ValidationStrategy = .anyCertFromChain
    ) {
        self.certUrls = certUrls
        self.validationStrategy = validationStrategy
    }

    lazy var pinnedCerts : Set<SecCertificate> = {
        Set(
            self.certUrls
                .compactMap { try? Data(contentsOf: $0) }
                .compactMap { SecCertificateCreateWithData(nil, $0 as CFData) }
        )
    }()

    open func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let trust = challenge.protectionSpace.serverTrust,
              SecTrustGetCertificateCount(trust) > 0
        else {
            log("Challenge failed:, unable to create cert trust", category: .challenge)
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard let certificateChain = SecTrustCopyCertificateChain(trust) as? [SecCertificate]
        else {
            log("Challenge failed:, unable to create cert chain", category: .challenge)
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        switch validationStrategy {
        case .anyCertFromChain:
            switch Set(certificateChain).intersection(pinnedCerts).isEmpty {
            case true:
                log("Challenge failed, no pinned cert intersection found", category: .challenge)
                completionHandler(.cancelAuthenticationChallenge, nil)
            case false:
                completionHandler(.useCredential, URLCredential(trust: trust))
            }
        case .allCertsFromChain:
            switch Set(certificateChain).subtracting(pinnedCerts).isEmpty {
            case false:
                log("Challenge failed, no pinned cert intersection found", category: .challenge)
                completionHandler(.cancelAuthenticationChallenge, nil)
            case true:
                completionHandler(.useCredential, URLCredential(trust: trust))
            }
        }
    }
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public final class CertPublicKeyVerificationChallenge: CertVerificationChallenge {
    private lazy var pinnedCertsKeys: Set<CFData> = {
        Set(
            self.pinnedCerts
                .compactMap { $0.secTrust?.secKey }
                .compactMap { $0.data }
        )
    }()

    override public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let trust = challenge.protectionSpace.serverTrust,
              SecTrustGetCertificateCount(trust) > 0
        else {
            log("Challenge failed:, unable to create cert trust", category: .challenge)
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard let certificateChain = SecTrustCopyCertificateChain(trust) as? [SecCertificate]
        else {
            log("Challenge failed:, unable to create cert chain", category: .challenge)
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let serverKeys = certificateChain.compactMap { $0.secTrust?.secKey?.data }

        switch validationStrategy {
        case .anyCertFromChain:
            switch Set(serverKeys).intersection(pinnedCertsKeys).isEmpty {
            case true:
                log("Challenge failed, no pinned cert intersection found", category: .challenge)
                completionHandler(.cancelAuthenticationChallenge, nil)
            case false:
                completionHandler(.useCredential, URLCredential(trust: trust))
            }
        case .allCertsFromChain:
            switch Set(serverKeys).subtracting(pinnedCertsKeys).isEmpty {
            case false:
                log("Challenge failed, no pinned cert intersection found", category: .challenge)
                completionHandler(.cancelAuthenticationChallenge, nil)
            case true:
                completionHandler(.useCredential, URLCredential(trust: trust))
            }
        }
    }
}

extension SecCertificate {
    var secTrust: SecTrust? {
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(self, SecPolicyCreateBasicX509(), &trust)

        switch status {
        case errSecSuccess:
            return trust
        default:
            log("SecStatus: \(status), err: \(SecCopyErrorMessageString(status, nil) ?? "undefined err" as CFString) ", category: .challenge)
            return .none
        }
    }
}

extension SecTrust {
    var secKey: SecKey? {
        SecTrustCopyKey(self)
    }
}

extension SecKey {
    var data: CFData? {
        SecKeyCopyExternalRepresentation(self, .none)
    }
}
