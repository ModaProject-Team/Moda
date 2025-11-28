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
import AVKit
import Combine

extension Notification.Name {
    static let postDeleted = Notification.Name("postDeleted")
    static let postLikeUpdated = Notification.Name("postLikeUpdated")
    static let postPaymentCompleted = Notification.Name("postPaymentCompleted")
    static let postUpdated = Notification.Name("postUpdated")
    static let paymentResponse = Notification.Name("paymentResponse")
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
    @State private var currentImageIndex: Int = 0
    @State private var showPaymentAlert = false
    @State private var paymentMessage = ""
    @State private var currentPayment: IamportPayment?
    @State private var selectedVideoURL: URL?
    @State private var relatedProducts: [Post] = []
    @State private var showComments = false
    @State private var commentPreview: [Comment] = []
    @State private var totalCommentCount = 0

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
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .topLeading) {
            if store.state.post != nil {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 36, height: 36)

                    BackButton {
                        navigator.pop()
                    }
                }
                .padding(.leading, 8)
                .padding(.top, 12)
            }
        }
        .task {
            store.send(.loadPost)
            await loadRelatedProducts()
            await loadCommentPreview()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("commentUpdated"))) { _ in
            Task {
                await loadCommentPreview()
            }
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
        }
        .fullScreenCover(item: Binding(
            get: { selectedVideoURL.map { VideoURLWrapper(url: $0) } },
            set: { selectedVideoURL = $0?.url }
        )) { wrapper in
            FullScreenVideoPlayer(videoURL: wrapper.url)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showComments) {
            if let post = store.state.post {
                CommentSheetView(postId: post.postId)
            }
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
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        mediaSection(post: post, geometry: geometry)

                        VStack(alignment: .leading, spacing: 24) {
                            titlePriceSection(post: post)
                                .padding(.top, 8)
                            sellerSection(post: post)
                            productInfoSection(post: post)

                            commentPreviewSection(post: post)

                            if let locationName = post.value1, !locationName.isEmpty,
                               let geolocation = post.geolocation {
                                tradeLocationSection(locationName: locationName, geolocation: geolocation)
                            }

                            if !post.hashTags.isEmpty {
                                hashTagsSection(hashTags: post.hashTags)
                            }

                            if !relatedProducts.isEmpty {
                                relatedProductsSection
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
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
    }

    private func mediaSection(post: PostResponse, geometry: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            if !post.files.isEmpty {
                TabView(selection: $currentImageIndex) {
                    ForEach(Array(post.files.enumerated()), id: \.offset) { index, fileURL in
                        MediaItemView(
                            fileURL: fileURL,
                            geometry: geometry,
                            onColorExtracted: { _ in },
                            onVideoTapped: { url in
                                selectedVideoURL = url
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: geometry.size.height * 0.4)

                if post.files.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<post.files.count, id: \.self) { index in
                            Circle()
                                .fill(currentImageIndex == index ? Color.blue1 : Color.gray3)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.bottom, 16)
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: geometry.size.height * 0.4)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
            }
        }
    }

    private func titlePriceSection(post: PostResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(post.title)
                .H1()
                .foregroundColor(.gray1)
                .multilineTextAlignment(.leading)

            if let price = post.price, price > 0 {
                Text("\(price.formatted())원")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.blue1)
            } else {
                Text("나눔")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.blue1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sellerSection(post: PostResponse) -> some View {
        Button {
            let people = People(
                id: post.creator.userId,
                name: post.creator.nick,
                statusMessage: nil,
                profileImageURL: post.creator.profileImage.flatMap { URL(string: "\(NetworkConfig.baseURL)/v1\($0)") }
            )
            navigator.push(.profileDetail(people: people, isCurrentUser: false))
        } label: {
            HStack(spacing: 12) {
                if let profileImage = post.creator.profileImage, !profileImage.isEmpty {
                    KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(profileImage)"))
                        .requestModifier(KFHeaders.modifier)
                        .placeholder {
                            Circle()
                                .fill(Color.gray3)
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray2)
                                }
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray3)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray2)
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.creator.nick)
                        .H2()
                        .foregroundColor(.gray1)

                    Text(store.formattedDate(from: post.createdAt))
                        .Body2()
                        .foregroundColor(.gray2)
                }

                Spacer()
            }
        }
    }

    private func productInfoSection(post: PostResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("상품 정보")
                .H2()
                .foregroundColor(.gray1)

            if let content = post.content, !content.isEmpty {
                Text(content)
                    .Body1()
                    .foregroundColor(.gray1)
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
            } else {
                Text("상품 설명이 없습니다.")
                    .Body2()
                    .foregroundColor(.gray2)
            }

            if let distance = post.distance {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green1)
                    Text(String(format: "%.1fkm", distance / 1000))
                        .Body2()
                        .foregroundColor(.gray2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tradeLocationSection(locationName: String, geolocation: PostGeolocation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("거래 장소")
                .H2()
                .foregroundColor(.gray1)

            Text(locationName)
                .Body1()
                .foregroundColor(.gray1)

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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func hashTagsSection(hashTags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("해시태그")
                .H2()
                .foregroundColor(.gray1)

            FlowLayout(spacing: 8) {
                ForEach(hashTags, id: \.self) { tag in
                    Text("#\(tag)")
                        .Body2()
                        .foregroundColor(.blue1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue1.opacity(0.1))
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func commentPreviewSection(post: PostResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("댓글")
                    .H2()
                    .foregroundColor(.gray1)

                Text("\(totalCommentCount)")
                    .Body2()
                    .foregroundColor(.gray2)

                Spacer()

                Button {
                    showComments = true
                } label: {
                    HStack(spacing: 4) {
                        Text("전체보기")
                            .Body2()
                            .foregroundColor(.blue1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.blue1)
                    }
                }
            }

            if commentPreview.isEmpty {
                Button {
                    showComments = true
                } label: {
                    HStack {
                        Text("첫 댓글을 남겨보세요")
                            .Body2()
                            .foregroundColor(.gray2)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray5)
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(commentPreview.prefix(2), id: \.commentId) { comment in
                        Button {
                            showComments = true
                        } label: {
                            CommentPreviewRow(comment: comment)
                        }

                        if comment.commentId != commentPreview.prefix(2).last?.commentId {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
                .background(Color.gray5)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var relatedProductsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("다른 사용자의 상품")
                .H2()
                .foregroundColor(.gray1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(relatedProducts) { product in
                        RelatedProductCard(product: product) {
                            navigator.push(.productDetail(postId: product.postId))
                        }
                    }
                }
            }
        }
    }

    private func floatingActionBar(post: PostResponse) -> some View {
        let isPaymentCompleted = !post.buyers.isEmpty
        let isFreeItem = post.price == nil || post.price == 0
        let isMyPost = store.state.isMyPost

        return HStack(spacing: 0) {
            HStack(spacing: 20) {
                Button {
                    let people = People(
                        id: post.creator.userId,
                        name: post.creator.nick,
                        statusMessage: nil,
                        profileImageURL: post.creator.profileImage.flatMap { URL(string: "\(NetworkConfig.baseURL)/v1\($0)") }
                    )
                    navigator.push(.profileDetail(people: people, isCurrentUser: false))
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
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }

                if isPaymentCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.pink1)
                        Text("\(store.state.likeCount)")
                            .Body2()
                            .foregroundColor(.white)
                    }

                    Text("거래완료")
                        .Body1()
                        .foregroundColor(.white)
                }
                else if isMyPost {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.pink1)
                        Text("\(store.state.likeCount)")
                            .Body2()
                            .foregroundColor(.white)
                    }

                    Button {
                        navigator.push(.productUpload(editMode: true, postId: post.postId))
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }

                    Button {
                        store.send(.showDeleteAlert)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                else {
                    Button {
                        store.send(.toggleLike)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: store.state.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 16))
                                .foregroundColor(store.state.isLiked ? .pink1 : .white)
                            Text("\(store.state.likeCount)")
                                .Body2()
                                .foregroundColor(.white)
                        }
                    }

                    if !isFreeItem {
                        Button {
                            startPayment(post: post)
                        } label: {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }

                    Button {
                        navigateToChat(post: post)
                    } label: {
                        Image(systemName: "message.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(Color.blue1)
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    private func navigateToChat(post: PostResponse) {
        Task {
            do {
                let response = try await ChatAPI.shared.getOrCreateRoom(opponentId: post.creator.userId)
                await MainActor.run {
                    navigator.push(.chatRoom(roomId: response.roomId, participantName: post.creator.nick))
                }
            } catch {
                print("Failed to create chat room: \(error)")
            }
        }
    }

    private func loadCommentPreview() async {
        do {
            let response = try await CommentAPI.shared.getComments(postId: postId)
            let comments = response.toDomain()

            await MainActor.run {
                self.commentPreview = comments
                // 댓글 + 답글 총 개수 계산
                var count = comments.count
                for comment in comments {
                    if let replies = comment.replies {
                        count += replies.count
                    }
                }
                self.totalCommentCount = count
            }
        } catch {
            print("Failed to load comment preview: \(error)")
        }
    }

    private func loadRelatedProducts() async {
        do {
            let response = try await NetworkService.shared.request(
                endpoint: PostRouter.getPosts(next: nil, limit: "5", category: nil),
                responseType: PostListResponse.self
            )
            await MainActor.run {
                self.relatedProducts = response.data
                    .map { $0.toDomain() }
                    .filter { $0.postId != postId }
                    .prefix(5)
                    .map { $0 }
            }
        } catch {
            print("Failed to load related products: \(error)")
        }
    }

    private func startPayment(post: PostResponse) {
        guard let price = post.price, price > 0 else { return }

        let merchantUid = "ios_\(postId)_\(Int(Date().timeIntervalSince1970 * 1000))"

        currentPayment = IamportPayment(
            pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"),
            merchant_uid: merchantUid,
            amount: "\(price)"
        ).then {
            $0.pay_method = PayMethod.card.rawValue
            $0.name = post.title
            $0.buyer_name = "장수지"
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

            await MainActor.run {
                store.send(.loadPost)
                NotificationCenter.default.post(name: .postPaymentCompleted, object: nil)
            }

            try? await Task.sleep(nanoseconds: 500_000_000)

            await MainActor.run {
                paymentMessage = "결제가 완료되었습니다.\n거래 품목: \(response.productName)\n금액: \(response.price)원"
                showPaymentAlert = true
            }
        } catch {
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

struct VideoURLWrapper: Identifiable {
    let id = UUID()
    let url: URL
}

struct MediaItemView: View {
    let fileURL: String
    let geometry: GeometryProxy
    let onColorExtracted: (Color) -> Void
    let onVideoTapped: (URL) -> Void

    var body: some View {
        let isVideo = fileURL.isVideoFile
        let fullURL = "\(NetworkConfig.baseURL)/v1\(fileURL)"

        ZStack {
            if isVideo {
                MediaImageView(
                    mediaURL: fileURL,
                    contentMode: .fill
                )
                .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                .clipped()
            } else {
                KFImage(URL(string: fullURL))
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
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                    .clipped()
            }

            if isVideo {
                PlayButton {
                    if let url = URL(string: fullURL) {
                        onVideoTapped(url)
                    }
                }
            }
        }
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
                onColorExtracted(Color(red: r, green: g, blue: b))
            }
        }
    }
}

struct CommentPreviewRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let profileImage = comment.creator.profileImage, !profileImage.isEmpty {
                KFImage(URL(string: "\(NetworkConfig.baseURL)/v1\(profileImage)"))
                    .requestModifier(KFHeaders.modifier)
                    .placeholder {
                        Circle()
                            .fill(Color.gray3)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray2)
                            }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray3)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray2)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.creator.nickname)
                        .Body2()
                        .foregroundColor(.gray1)
                        .fontWeight(.semibold)

                    Text(comment.createdAt.toRelativeTimeString())
                        .Body2()
                        .foregroundColor(.gray2)
                }

                Text(comment.content)
                    .Body2()
                    .foregroundColor(.gray1)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct RelatedProductCard: View {
    let product: Post
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                if let firstFile = product.files.first {
                    MediaImageView(mediaURL: firstFile, contentMode: .fill)
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray4)
                        .frame(width: 140, height: 140)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray2)
                        }
                }

                Text(product.title)
                    .Body2()
                    .foregroundColor(.gray1)
                    .lineLimit(1)
                    .frame(width: 140, alignment: .leading)

                if let price = product.price, price > 0 {
                    Text("\(price.formatted())원")
                        .Body2()
                        .foregroundColor(.blue1)
                        .fontWeight(.semibold)
                } else {
                    Text("나눔")
                        .Body2()
                        .foregroundColor(.blue1)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(postId: "test")
            .environmentObject(AppNavigator.shared)
    }
}
