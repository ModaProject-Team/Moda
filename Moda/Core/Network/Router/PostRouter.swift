//
//  PostRouter.swift
//  Moda
//
//  Created by 금가경 on 11/16/24.
//

import Foundation

enum FileType {
    case image
    case video
}

struct FileData {
    let data: Data
    let type: FileType
}

/// 게시글 관련 API 엔드포인트
enum PostRouter {
    /// 파일 업로드
    case uploadFiles(files: [FileData])

    /// 게시글 작성
    case createPost(
        category: String,
        title: String,
        price: Int?,
        content: String?,
        value1: String?,
        content2: String?,
        content3: String?,
        content4: String?,
        content5: String?,
        files: [String],
        longitude: Double?,
        latitude: Double?
    )

    /// 게시글 목록 조회
    case getPosts(next: String?, limit: String?, category: [String]?)

    /// 게시글 상세 조회
    case getPost(postId: String)

    /// 게시글 수정
    case updatePost(
        postId: String,
        category: String?,
        title: String?,
        price: Int?,
        content: String?,
        value1: String?,
        content2: String?,
        content3: String?,
        content4: String?,
        content5: String?,
        files: [String]?,
        longitude: Double?,
        latitude: Double?
    )

    /// 게시글 삭제
    case deletePost(postId: String)

    /// 게시글 좋아요/취소
    case likePost(postId: String, likeStatus: Bool)

    /// 좋아요한 게시글 조회
    case getMyLikedPosts(next: String?, limit: String?, category: [String]?)

    /// 특정 유저 게시글 조회
    case getUserPosts(userId: String, next: String?, limit: String?, category: [String]?)

    /// 해시태그 검색
    case searchHashtags(next: String?, limit: String?, category: [String]?, hashTag: String)

    /// 팔로우 피드 조회
    case getFeed(next: String?, limit: String?, category: [String]?)

    /// 위치기반 게시글 검색
    case getPostsByGeolocation(
        category: [String]?,
        longitude: Double?,
        latitude: Double?,
        maxDistance: Double?,
        orderBy: String?,
        sortBy: String?
    )

    /// 제목 검색
    case searchPosts(title: String, category: [String]?)

    /// 결제 검증
    case validatePayment(impUid: String, postId: String)
}

extension PostRouter: Endpoint {
    var baseURL: String {
        return NetworkConfig.baseURL
    }

    var path: String {
        switch self {
        case .validatePayment:
            return "/v1/payments/validation"
        default:
            let basePath = "/v1/posts"
            let subPath: String

            switch self {
            case .uploadFiles:
                subPath = "/files"
            case .createPost, .getPosts:
                subPath = ""
            case .getPost(let postId), .updatePost(let postId, _, _, _, _, _, _, _, _, _, _, _, _), .deletePost(let postId):
                subPath = "/\(postId)"
            case .likePost(let postId, _):
                subPath = "/\(postId)/like"
            case .getMyLikedPosts:
                subPath = "/likes/me"
            case .getUserPosts(let userId, _, _, _):
                subPath = "/users/\(userId)"
            case .searchHashtags:
                subPath = "/hashtags"
            case .getFeed:
                subPath = "/feed"
            case .getPostsByGeolocation:
                subPath = "/geolocation"
            case .searchPosts:
                subPath = "/search"
            default:
                subPath = ""
            }

            return basePath + subPath
        }
    }

    var method: HTTPMethod {
        switch self {
        case .uploadFiles, .createPost, .likePost, .validatePayment:
            return .post
        case .updatePost:
            return .put
        case .deletePost:
            return .delete
        default:
            return .get
        }
    }

    var headers: [String: String]? {
        var headers: [String: String] = [
            "SesacKey": NetworkConfig.sesacKey,
            "ProductId": NetworkConfig.productId
        ]

        switch self {
        case .uploadFiles:
            break
        default:
            headers["Content-Type"] = "application/json"
        }

        if let accessToken = TokenManager.shared.accessToken {
            headers["Authorization"] = accessToken
        }

        return headers
    }

    var parameters: [String: Any]? {
        switch self {
        case .createPost(let category, let title, let price, let content, let value1, let content2, let content3, let content4, let content5, let files, let longitude, let latitude):
            var params: [String: Any] = [
                "category": category,
                "title": title,
                "files": files
            ]
            if let price = price { params["price"] = price }
            if let content = content { params["content"] = content }
            if let value1 = value1 { params["value1"] = value1 }
            if let content2 = content2 { params["content2"] = content2 }
            if let content3 = content3 { params["content3"] = content3 }
            if let content4 = content4 { params["content4"] = content4 }
            if let content5 = content5 { params["content5"] = content5 }
            if let lon = longitude { params["longitude"] = lon }
            if let lat = latitude { params["latitude"] = lat }

            return params

        case .updatePost(_, let category, let title, let price, let content, let value1, let content2, let content3, let content4, let content5, let files, let longitude, let latitude):
            var params: [String: Any] = [:]
            if let category = category { params["category"] = category }
            if let title = title { params["title"] = title }
            if let price = price { params["price"] = price }
            if let content = content { params["content"] = content }
            if let value1 = value1 { params["value1"] = value1 }
            if let content2 = content2 { params["content2"] = content2 }
            if let content3 = content3 { params["content3"] = content3 }
            if let content4 = content4 { params["content4"] = content4 }
            if let content5 = content5 { params["content5"] = content5 }
            if let files = files { params["files"] = files }
            if let lon = longitude { params["longitude"] = lon }
            if let lat = latitude { params["latitude"] = lat }

            return params.isEmpty ? nil : params

        case .likePost(_, let likeStatus):
            return ["like_status": likeStatus]

        case .validatePayment(let impUid, let postId):
            return [
                "imp_uid": impUid,
                "post_id": postId
            ]

        default:
            return nil
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getPosts(let next, let limit, let category):
            var items: [URLQueryItem] = []
            if let next = next { items.append(URLQueryItem(name: "next", value: next)) }
            if let limit = limit { items.append(URLQueryItem(name: "limit", value: limit)) }
            if let category = category {
                for cat in category {
                    items.append(URLQueryItem(name: "category", value: cat))
                }
            }
            return items.isEmpty ? nil : items

        case .getMyLikedPosts(let next, let limit, let category), .getFeed(let next, let limit, let category):
            var items: [URLQueryItem] = []
            if let next = next { items.append(URLQueryItem(name: "next", value: next)) }
            if let limit = limit { items.append(URLQueryItem(name: "limit", value: limit)) }
            if let category = category {
                for cat in category {
                    items.append(URLQueryItem(name: "category", value: cat))
                }
            }
            return items.isEmpty ? nil : items

        case .getUserPosts(_, let next, let limit, let category):
            var items: [URLQueryItem] = []
            if let next = next { items.append(URLQueryItem(name: "next", value: next)) }
            if let limit = limit { items.append(URLQueryItem(name: "limit", value: limit)) }
            if let category = category {
                for cat in category {
                    items.append(URLQueryItem(name: "category", value: cat))
                }
            }
            return items.isEmpty ? nil : items

        case .searchHashtags(let next, let limit, let category, let hashTag):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "hashTag", value: hashTag)
            ]
            if let next = next { items.append(URLQueryItem(name: "next", value: next)) }
            if let limit = limit { items.append(URLQueryItem(name: "limit", value: limit)) }
            if let category = category {
                for cat in category {
                    items.append(URLQueryItem(name: "category", value: cat))
                }
            }
            return items

        case .getPostsByGeolocation(let category, let longitude, let latitude, let maxDistance, let orderBy, let sortBy):
            var items: [URLQueryItem] = []
            if let category = category {
                for cat in category {
                    items.append(URLQueryItem(name: "category", value: cat))
                }
            }
            if let lon = longitude { items.append(URLQueryItem(name: "longitude", value: String(lon))) }
            if let lat = latitude { items.append(URLQueryItem(name: "latitude", value: String(lat))) }
            if let maxDist = maxDistance { items.append(URLQueryItem(name: "maxDistance", value: String(maxDist))) }
            if let order = orderBy { items.append(URLQueryItem(name: "order_by", value: order)) }
            if let sort = sortBy { items.append(URLQueryItem(name: "sort_by", value: sort)) }
            return items.isEmpty ? nil : items

        case .searchPosts(let title, let category):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "title", value: title)
            ]
            if let category = category {
                for cat in category {
                    items.append(URLQueryItem(name: "category", value: cat))
                }
            }
            return items

        default:
            return nil
        }
    }

    var isMultipart: Bool {
        switch self {
        case .uploadFiles:
            return true
        default:
            return false
        }
    }

    func multipartData() -> (data: Data, boundary: String)? {
        guard case .uploadFiles(let files) = self else {
            return nil
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        for (index, file) in files.enumerated() {
            let (filename, contentType) = getFileMetadata(for: file.type, index: index)

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
            body.append(file.data)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return (body, boundary)
    }

    private func getFileMetadata(for type: FileType, index: Int) -> (filename: String, contentType: String) {
        switch type {
        case .image:
            return ("file\(index)_\(Int(Date().timeIntervalSince1970 * 1000)).jpg", "image/jpeg")
        case .video:
            return ("file\(index)_\(Int(Date().timeIntervalSince1970 * 1000)).mp4", "video/mp4")
        }
    }
}
