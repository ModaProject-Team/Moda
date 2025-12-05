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

    @State private var isLoading = true
    @State private var showAppInstallAlert = false

    var body: some View {
        ZStack {
            WebViewRepresentable(
                userCode: userCode,
                payment: payment,
                completion: completion,
                isLoading: $isLoading,
                onAppInstallRequired: {
                    showAppInstallAlert = true
                }
            )
        }
        .alert("앱 설치 필요", isPresented: $showAppInstallAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("결제를 위해서는 해당 앱 설치가 필요합니다.\n다른 결제 수단을 선택해주세요.")
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let userCode: String
    let payment: IamportPayment
    let completion: (IamportResponse?) -> Void
    @Binding var isLoading: Bool
    let onAppInstallRequired: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .white
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if !context.coordinator.hasStartedPayment {
            context.coordinator.hasStartedPayment = true

            // 결제 시작
            Iamport.shared.paymentWebView(
                webViewMode: webView,
                userCode: userCode,
                payment: payment
            ) { response in
                DispatchQueue.main.async {
                    isLoading = false
                    completion(response)
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, onAppInstallRequired: onAppInstallRequired)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        var hasStartedPayment = false
        let onAppInstallRequired: () -> Void

        init(isLoading: Binding<Bool>, onAppInstallRequired: @escaping () -> Void) {
            self._isLoading = isLoading
            self.onAppInstallRequired = onAppInstallRequired
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

            // 카드사 앱/간편결제 URLScheme 처리
            if UIApplication.shared.canOpenURL(url) {
                // 앱이 설치되어 있으면 실행
                UIApplication.shared.open(url, options: [:])
                decisionHandler(.cancel)
            } else {
                // 앱 미설치: 앱스토어로 이동 또는 Alert 표시
                if urlString.contains("itms-apps") || urlString.hasPrefix("itms-apps://") {
                    // 앱스토어 URL이면 바로 실행
                    UIApplication.shared.open(url, options: [:])
                } else {
                    // 일반 URLScheme이면 사용자에게 Alert 표시
                    DispatchQueue.main.async {
                        self.onAppInstallRequired()
                    }
                }
                decisionHandler(.cancel)
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}
