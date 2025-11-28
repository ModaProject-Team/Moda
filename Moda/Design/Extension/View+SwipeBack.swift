//
//  View+SwipeBack.swift
//  Moda
//
//  Created by 금가경 on 11/29/25.
//

import SwiftUI

extension View {
    /// 커스텀 백 버튼을 사용하면서도 스와이프로 뒤로 갈 수 있도록 설정합니다
    func enableSwipeBack() -> some View {
        self.background(
            SwipeBackHelper()
        )
    }
}

private struct SwipeBackHelper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        SwipeBackViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

private class SwipeBackViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // UINavigationController의 스와이프 제스처 활성화
        if let navigationController = self.navigationController {
            navigationController.interactivePopGestureRecognizer?.isEnabled = true
            navigationController.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}
