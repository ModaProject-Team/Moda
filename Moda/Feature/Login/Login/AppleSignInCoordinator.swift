//
//  AppleSignInCoordinator.swift
//  Moda
//
//  Created by Suji Jang on 11/28/25.
//

import AuthenticationServices
import SwiftUI

/// Apple Sign In 인증을 처리하는 Coordinator
///
/// ASAuthorizationController의 delegate를 처리하고
/// async/await 패턴으로 결과를 반환합니다.
final class AppleSignInCoordinator: NSObject {

    /// Apple Sign In 결과
    struct AppleSignInResult {
        let identityToken: String
        let userIdentifier: String
        let fullName: PersonNameComponents?
        let email: String?
    }

    private var continuation: CheckedContinuation<AppleSignInResult, Error>?

    /// Apple Sign In 시작
    ///
    /// - Returns: Apple Sign In 결과 (identityToken, userID, fullName, email)
    /// - Throws: 인증 실패 또는 취소 시 에러
    func signIn() async throws -> AppleSignInResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }

    /// 특정 사용자의 자격 증명 상태 확인
    ///
    /// - Parameter userID: Apple User ID
    /// - Returns: 자격 증명 상태
    static func getCredentialState(for userID: String) async throws -> ASAuthorizationAppleIDProvider.CredentialState {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        return try await appleIDProvider.credentialState(forUserID: userID)
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: NSError(
                domain: "AppleSignIn",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Apple 자격 증명을 가져올 수 없습니다"]
            ))
            continuation = nil
            return
        }

        guard let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            continuation?.resume(throwing: NSError(
                domain: "AppleSignIn",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Identity Token을 가져올 수 없습니다"]
            ))
            continuation = nil
            return
        }

        let result = AppleSignInResult(
            identityToken: identityToken,
            userIdentifier: appleIDCredential.user,
            fullName: appleIDCredential.fullName,
            email: appleIDCredential.email
        )

        continuation?.resume(returning: result)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let nsError = error as NSError

        // 사용자가 취소한 경우
        if nsError.code == ASAuthorizationError.canceled.rawValue {
            continuation?.resume(throwing: NSError(
                domain: "AppleSignIn",
                code: ASAuthorizationError.canceled.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Apple 로그인이 취소되었습니다"]
            ))
        } else {
            continuation?.resume(throwing: error)
        }

        continuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // 현재 활성화된 window를 반환
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}
