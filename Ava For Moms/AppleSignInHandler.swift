import AuthenticationServices
import UIKit

// Separate NSObject subclass so AuthManager doesn't inherit NSObject.
// @Observable + NSObject + @MainActor causes Swift 6 macro expansion conflicts.

final class AppleSignInHandler: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    var continuation: CheckedContinuation<ASAuthorization, Error>?

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        continuation?.resume(returning: authorization)
        continuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        else { fatalError("No UIWindowScene found") }
        return scene.windows.first { $0.isKeyWindow } ?? scene.windows.first ?? UIWindow(windowScene: scene)
    }
}
