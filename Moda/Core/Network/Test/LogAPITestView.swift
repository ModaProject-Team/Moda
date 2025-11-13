//
//  LogAPITestView.swift
//  Moda
//
//  Created by 금가경 on 11/13/24.
//

import SwiftUI
import Combine

struct LogAPITestState {
    var resultMessage: String = "테스트를 시작하려면 버튼을 눌러주세요."
    var isSuccess: Bool = true
    var isLoading: Bool = false
    var logs: [Log] = []
}

enum LogAPITestIntent {
    case getLogsButtonTapped
}

final class LogAPITestStore: ObservableObject {
    @Published private(set) var state = LogAPITestState()

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    @MainActor
    func send(_ intent: LogAPITestIntent) {
        Task {
            switch intent {
            case .getLogsButtonTapped:
                await testGetLogs()
            }
        }
    }

    @MainActor
    private func testGetLogs() async {
        state.isLoading = true
        state.resultMessage = "로그 조회 테스트 중...\n"

        do {
            let response = try await networkService.request(
                endpoint: APIRouter.getLogs,
                responseType: LogResponse.self
            )

            state.logs = response.logs

            let logList = response.logs.enumerated()
                .map { """
                    \($0 + 1). [\(formatDate($1.date))] \($1.method) \($1.routePath)
                       Status: \($1.statusCode) | Name: \($1.name)
                    """ }
                .joined(separator: "\n")

            state.resultMessage += """

            ✅ 로그 조회 성공!
            총 로그 개수: \(response.count)개

            \(logList)

            """

            state.isSuccess = true
        } catch {
            handleError(error, testName: "로그 조회")
        }

        state.isLoading = false
    }

    @MainActor
    private func handleError(_ error: Error, testName: String) {
        state.resultMessage += "❌ \(testName) 실패\n"

        if let networkError = error as? NetworkError {
            state.resultMessage += "Error: \(networkError.localizedDescription)\n"
        } else {
            state.resultMessage += "Error: \(error.localizedDescription)\n"
        }

        state.isSuccess = false
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MM/dd HH:mm:ss"
        displayFormatter.locale = Locale(identifier: "ko_KR")
        displayFormatter.timeZone = TimeZone.current

        return displayFormatter.string(from: date)
    }
}

struct LogAPITestView: View {
    @StateObject private var store = LogAPITestStore()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    resultSection

                    Divider()

                    buttonListSection
                }
                .padding()
            }
            .navigationTitle("Log API 테스트")
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            resultHeader

            ScrollView {
                Text(store.state.resultMessage)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(store.state.isSuccess ? .green : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(height: 200)
        }
    }

    private var resultHeader: some View {
        HStack {
            Text("테스트 결과")
                .font(.headline)

            if store.state.isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }

    private var buttonListSection: some View {
        VStack(spacing: 20) {
            LogTestButton(title: "로그 조회", isLoading: store.state.isLoading) {
                store.send(.getLogsButtonTapped)
            }
        }
    }
}

struct LogTestButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .disabled(isLoading)
    }
}

#Preview {
    LogAPITestView()
}
