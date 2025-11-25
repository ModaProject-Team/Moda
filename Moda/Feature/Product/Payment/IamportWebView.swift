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

    var body: some View {
        ZStack {
            WebViewRepresentable(
                userCode: userCode,
                payment: payment,
                completion: completion,
                isLoading: $isLoading
            )
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let userCode: String
    let payment: IamportPayment
    let completion: (IamportResponse?) -> Void
    @Binding var isLoading: Bool

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
        Coordinator(isLoading: $isLoading)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        var hasStartedPayment = false

        init(isLoading: Binding<Bool>) {
            self._isLoading = isLoading
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
