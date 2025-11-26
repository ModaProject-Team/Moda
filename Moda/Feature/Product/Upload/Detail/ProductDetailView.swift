//
//  ProductDetailView.swift
//  Moda
//
//  Created by Suji Jang on 11/22/24.
//

import SwiftUI
import Kingfisher
import MapKit
import iamport_ios

extension Notification.Name {
    static let postDeleted = Notification.Name("postDeleted")
    static let postLikeUpdated = Notification.Name("postLikeUpdated")
    static let postPaymentCompleted = Notification.Name("postPaymentCompleted")
}

extension IamportPayment: @retroactive Identifiable {
    public var id: String {
        return merchant_uid
    }
}

struct ProductDetailView: View {

    let postId: String
    @StateObject private var store: ProductDetailStore
    @EnvironmentObject var navigator: AppNavigator
    @State private var selectedTab: Int = 0
    @State private var dominantColor: Color = .gray
    @State private var currentImageIndex: Int = 0
    @State private var showPaymentAlert = false
    @State private var paymentMessage = ""
    @State private var currentPayment: IamportPayment?

    init(postId: String) {
        self.postId = postId
        self._store = StateObject(wrappedValue: ProductDetailStore(postId: postId))
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            if store.state.isLoading {
                ProgressView()
            } else if let error = store.state.errorMessage {
                errorView(error: error)
            } else if let post = store.state.post {
                contentView(post: post)
                    .ignoresSafeArea(edges: .top)
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .top) {
            if store.state.post != nil {
                ZStack(alignment: .top) {
                    LinearGradient(
                        colors: [.black.opacity(0.5), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .ignoresSafeArea()

                    HStack {
                        Button {
                            navigator.pop()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                }
            }
        }
        .task {
            store.send(.loadPost)
        }
        .alert("게시글 삭제", isPresented: Binding(
            get: { store.state.showDeleteAlert },
            set: { if !$0 { store.send(.dismissDeleteAlert) } }
        )) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                store.send(.deletePost)
            }
        } message: {
            Text("이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.")
        }
        .disabled(store.state.isDeleting)
        .overlay {
            if store.state.isDeleting {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .postDeleted)) { _ in
            navigator.popToRoot()
        }
        .alert("결제 결과", isPresented: $showPaymentAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(paymentMessage)
        }
        .fullScreenCover(item: $currentPayment) { payment in
            IamportWebView(
                userCode: "imp14511373",
                payment: payment
            ) { response in
                currentPayment = nil
                handlePaymentResponse(response)
            }
            .ignoresSafeArea()
        }
    }

    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Text("오류가 발생했습니다")
                .H2()
                .foregroundColor(.gray1)
            Text(error)
                .Body2()
                .foregroundColor(.gray2)
            Button("다시 시도") {
                store.send(.loadPost)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue1)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }

    private func contentView(post: PostResponse) -> some View {
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    VStack(spacing: 0) {
                        ZStack(alignment: .bottom) {
                            if !post.files.isEmpty {
                                TabView(selection: $currentImageIndex) {
                                    ForEach(Array(post.files.enumerated()), id: \.offset) { index, imageURL in
                                        KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(imageURL)"))
                                            .requestModifier(KFHeaders.modifier)
                                            .onSuccess { result in
                                                extractColor(from: result.image)
                                            }
                                            .placeholder {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                            }
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                                            .clipped()
                                            .tag(index)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                .frame(height: geometry.size.height * 0.4)
                                
                                if post.files.count > 1 {
                                    HStack(spacing: 6) {
                                        ForEach(0..<post.files.count, id: \.self) { index in
                                            Circle()
                                                .fill(currentImageIndex == index ? Color.white : Color.white.opacity(0.5))
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                    .padding(.bottom, 16)
                                }
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: geometry.size.height * 0.6)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray)
                                    }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {

                            Text(post.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                                .padding(.vertical, 16)

                                if let price = post.price, price > 0 {
                                    Text("\(price.formatted())원")
                                        .H2()
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .padding(.bottom, 20)
                                } else {
                                    Text("나눔")
                                        .H2()
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .padding(.bottom, 20)
                                }
                            
                            
                            VStack(spacing: 0) {
                                HStack(spacing: 0) {
                                    tabButton(title: "상세 정보", index: 0)
                                        .frame(maxWidth: .infinity)
                                    tabButton(title: "거래 장소", index: 1)
                                        .frame(maxWidth: .infinity)
                                }
                                .padding(.bottom, 12)
                                
                                GeometryReader { tabGeometry in
                                    Rectangle()
                                        .fill(Color.black)
                                        .frame(width: tabGeometry.size.width / 2, height: 2)
                                        .offset(x: selectedTab == 0 ? 0 : tabGeometry.size.width / 2)
                                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                                }
                                .frame(height: 2)
                            }
                            .padding(.bottom, 16)
                            
                            if selectedTab == 0 {
                                productInfoTab(post: post)
                            } else {
                                tradeLocationTab(post: post)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                }
                .scrollIndicators(.hidden)
                Spacer()
                floatingActionBar(post: post)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    private func tabButton(title: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(selectedTab == index ? .semibold : .regular)
                .foregroundColor(selectedTab == index ? .black : .gray)
        }
    }

    private func productInfoTab(post: PostResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundColor(.black.opacity(0.8))
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            } else {
                Text("상품 설명이 없습니다.")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.pink1)
                    Text("\(store.state.likeCount)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(store.formattedDate(from: post.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tradeLocationTab(post: PostResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let locationName = post.value1, !locationName.isEmpty,
               let geolocation = post.geolocation {
                Text(locationName)
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)

                Map(initialPosition: .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(
                            latitude: geolocation.latitude,
                            longitude: geolocation.longitude
                        ),
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                )) {
                    Annotation("", coordinate: CLLocationCoordinate2D(
                        latitude: geolocation.latitude,
                        longitude: geolocation.longitude
                    )) {
                        Image("pin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Text("거래 장소 정보가 없습니다.")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func floatingActionBar(post: PostResponse) -> some View {
        let isPaymentCompleted = !post.buyers.isEmpty
        let isFreeItem = post.price == nil || post.price == 0
        let isMyPost = store.state.isMyPost

        return HStack(spacing: 16) {
            Button {
                //TODO: Navigate to seller profile
            } label: {
                if let profileImage = post.creator.profileImage, !profileImage.isEmpty {
                    KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(profileImage)"))
                        .requestModifier(KFHeaders.modifier)
                        .placeholder {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }

            Text("|")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))

            if isPaymentCompleted {
                Text("거래완료")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            else if isMyPost {
                Button {
                    // TODO: 수정 화면으로 이동
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                }

                Button {
                    store.send(.showDeleteAlert)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                }
            }
            
            else {
                if !isFreeItem {
                    Button {
                        startPayment(post: post)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                    }
                }

                Button {
                    //TODO: Navigate to chat
                } label: {
                    Image(systemName: "message.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }

                Button {
                    store.send(.toggleLike)
                } label: {
                    Image(systemName: store.state.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(store.state.isLiked ? .pink1 : .white)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color.blue1)
        )
    }

    private func extractColor(from image: KFCrossPlatformImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let cgImage = image.cgImage else { return }

            let width = 1
            let height = 1
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo
            ) else { return }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

            guard let data = context.data else { return }
            let pointer = data.bindMemory(to: UInt8.self, capacity: 4)

            let r = CGFloat(pointer[0]) / 255.0
            let g = CGFloat(pointer[1]) / 255.0
            let b = CGFloat(pointer[2]) / 255.0

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.dominantColor = Color(red: r, green: g, blue: b)
                }
            }
        }
    }

    // MARK: - Payment
    private func startPayment(post: PostResponse) {
        guard let price = post.price, price > 0 else { return }

        // merchant_uid: 고유한 주문 번호 생성 (product_id + timestamp)
        let merchantUid = "ios_\(postId)_\(Int(Date().timeIntervalSince1970 * 1000))"

        // IamportPayment 생성
        currentPayment = IamportPayment(
            pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"),
            merchant_uid: merchantUid,
            amount: "\(price)"
        ).then {
            $0.pay_method = PayMethod.card.rawValue
            $0.name = post.title
            $0.buyer_name = "장수지" // TODO: 실제 사용자 이름으로 변경
            $0.app_scheme = "moda"
        }
    }

    private func handlePaymentResponse(_ response: IamportResponse?) {
        guard let response = response else {
            paymentMessage = "결제 응답을 받지 못했습니다."
            showPaymentAlert = true
            return
        }

        if response.success == true, let impUid = response.imp_uid {
            // 결제 성공 - 서버에 결제 검증 요청
            Task {
                await validatePayment(impUid: impUid)
            }
        } else {
            paymentMessage = "결제가 취소되었습니다."
            print(response.error_msg ?? "알 수 없는 오류")
            showPaymentAlert = true
        }
    }

    private func validatePayment(impUid: String) async {
        do {
            let response = try await NetworkService.shared.request(
                endpoint: PostRouter.validatePayment(impUid: impUid, postId: postId),
                responseType: PaymentValidationResponse.self
            )

            // 결제 검증 성공 - 게시글 데이터 다시 로드하여 UI 업데이트
            await MainActor.run {
                store.send(.loadPost)
                NotificationCenter.default.post(name: .postPaymentCompleted, object: nil)
            }

            // 잠시 대기 후 알림 표시 (데이터 로딩 완료 후)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초

            await MainActor.run {
                paymentMessage = "결제가 완료되었습니다.\n거래 품목: \(response.productName)\n금액: \(response.price)원"
                showPaymentAlert = true
            }
        } catch {
            // 결제 검증 실패
            await MainActor.run {
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .serverError(let message):
                        paymentMessage = "결제 검증 실패: \(message)"
                    default:
                        paymentMessage = "결제 검증 중 오류가 발생했습니다."
                    }
                } else {
                    paymentMessage = "결제 검증 중 오류가 발생했습니다."
                }
                showPaymentAlert = true
            }
        }
    }

}

#Preview {
    NavigationStack {
        ProductDetailView(postId: "test")
            .environmentObject(AppNavigator.shared)
    }
}
