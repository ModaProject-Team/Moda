//
//  IamportWebView.swift
//  Moda
//
//  Created by Suji Jang on 11/25/24.
//

import SwiftUI
import WebKit
import iamport_ios

struct IamportWebView: View {
    let userCode: String
    let payment: IamportPayment
    let completion: (IamportResponse?) -> Void

    @State private var webViewStatus: WebViewStatus = .loading
    @State private var showAppInstallAlert = false
    @State private var showTimeoutAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        WebViewRepresentable(
            userCode: userCode,
            payment: payment,
            completion: completion,
            webViewStatus: $webViewStatus,
            onAppInstallRequired: {
                showAppInstallAlert = true
            },
            onTimeout: {
                showTimeoutAlert = true
            },
            onError: { message in
                errorMessage = message
                showErrorAlert = true
            }
        )
        .alert("앱 설치 필요", isPresented: $showAppInstallAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("결제를 위해서는 해당 앱 설치가 필요합니다.\n다른 결제 수단을 선택해주세요.")
        }
        .alert("결제 시간 초과", isPresented: $showTimeoutAlert) {
            Button("확인", role: .cancel) {
                completion(nil)
            }
        } message: {
            Text("결제 처리 시간이 초과되었습니다.\n다시 시도해주세요.")
        }
        .alert("결제 오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) {
                completion(nil)
            }
        } message: {
            Text(errorMessage)
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let userCode: String
    let payment: IamportPayment
    let completion: (IamportResponse?) -> Void
    @Binding var webViewStatus: WebViewStatus
    let onAppInstallRequired: () -> Void
    let onTimeout: () -> Void
    let onError: (String) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .white
        webView.scrollView.bounces = false

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if !context.coordinator.hasStartedPayment {
            context.coordinator.hasStartedPayment = true

            // 타임아웃 타이머 시작
            context.coordinator.startTimeoutTimer()

            // 결제 시작
            Iamport.shared.paymentWebView(
                webViewMode: webView,
                userCode: userCode,
                payment: payment
            ) { response in
                DispatchQueue.main.async {
                    context.coordinator.cancelTimeoutTimer()
                    webViewStatus = .ready
                    completion(response)
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            webViewStatus: $webViewStatus,
            onAppInstallRequired: onAppInstallRequired,
            onTimeout: onTimeout,
            onError: onError
        )
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var webViewStatus: WebViewStatus
        var hasStartedPayment = false
        let onAppInstallRequired: () -> Void
        let onTimeout: () -> Void
        let onError: (String) -> Void

        private var timeoutTimer: Timer?

        init(
            webViewStatus: Binding<WebViewStatus>,
            onAppInstallRequired: @escaping () -> Void,
            onTimeout: @escaping () -> Void,
            onError: @escaping (String) -> Void
        ) {
            self._webViewStatus = webViewStatus
            self.onAppInstallRequired = onAppInstallRequired
            self.onTimeout = onTimeout
            self.onError = onError
        }

        deinit {
            cancelTimeoutTimer()
        }

        /// 타임아웃 타이머 시작
        func startTimeoutTimer() {
            cancelTimeoutTimer()

            timeoutTimer = Timer.scheduledTimer(withTimeInterval: WebViewConfig.timeout, repeats: false) { [weak self] _ in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    self.webViewStatus = .timeout
                    self.onTimeout()
                }
            }
        }

        /// 타임아웃 타이머 취소
        func cancelTimeoutTimer() {
            timeoutTimer?.invalidate()
            timeoutTimer = nil
        }

        /// URL 이동 전 처리: 카드사 앱 실행 or 앱스토어 이동
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let urlString = url.absoluteString

            // http/https는 WebView에서 처리
            if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
                decisionHandler(.allow)
                return
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // 페이지 로딩 시작
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 페이지 로딩 완료
            DispatchQueue.main.async {
                self.webViewStatus = .ready
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            cancelTimeoutTimer()

            let nsError = error as NSError

            // 사용자가 취소한 경우 무시
            if nsError.code == NSURLErrorCancelled {
                return
            }

            DispatchQueue.main.async {
                let errorMessage: String

                switch nsError.code {
                case NSURLErrorNotConnectedToInternet:
                    errorMessage = "인터넷 연결을 확인해주세요."

                case NSURLErrorTimedOut:
                    errorMessage = "요청 시간이 초과되었습니다."

                case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                    errorMessage = "서버에 연결할 수 없습니다."

                case NSURLErrorNetworkConnectionLost:
                    errorMessage = "네트워크 연결이 끊어졌습니다."

                default:
                    errorMessage = "결제 페이지를 불러올 수 없습니다.\n\(nsError.localizedDescription)"
                }

                self.webViewStatus = .error(errorMessage)
                self.onError(errorMessage)
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            // 페이지 로딩 실패 (초기 로딩 실패)
            self.webView(webView, didFail: navigation, withError: error)
        }
    }
}
