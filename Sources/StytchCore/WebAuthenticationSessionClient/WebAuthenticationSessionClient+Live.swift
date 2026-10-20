import AuthenticationServices

#if !os(watchOS)
@available(tvOS 16.0, *)
extension WebAuthenticationSessionClient {
    static let live: Self = .init { parameters in
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: parameters.url, callbackURLScheme: parameters.callbackUrlScheme) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let url = url else {
                    continuation.resume(throwing: StytchSDKError.missingURL)
                    return
                }
                do {
                    if parameters.clientType == ClientType.consumer {
                        guard let token = try StytchClient.tokenValues(for: url)?.2 else {
                            continuation.resume(throwing: StytchSDKError.deeplinkMissingToken)
                            return
                        }
                        continuation.resume(returning: (token, url))
                    } else {
                        guard let token = try StytchB2BClient.tokenValues(for: url)?.2 else {
                            continuation.resume(throwing: StytchSDKError.deeplinkMissingToken)
                            return
                        }
                        continuation.resume(returning: (token, url))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            #if !os(tvOS)
            session.presentationContextProvider = parameters.presentationContextProvider
            #endif
            // Holos: run every OAuth flow in a private cookie jar. Stytch's OAuth state is a
            // 10-minute, single-use `oauth_state` cookie on the project's login domain, and in
            // the default (shared-with-Safari) mode that cookie is exposed to Safari's tracking
            // protection, to a dashboard login running in Safari, and to replayed callbacks,
            // any of which surfaces as `oauth_invalid_state` from the callback. An ephemeral
            // session isolates the cookie for the life of the flow and also skips the
            // "wants to use <domain> to sign in" system prompt.
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
    }
}
#endif

#if !os(tvOS) && !os(watchOS)
extension WebAuthenticationSessionClient {
    final class DefaultPresentationProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
        @MainActor
        func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
            .init()
        }
    }
}
#endif
