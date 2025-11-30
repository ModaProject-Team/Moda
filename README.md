<img width="100" src="https://github.com/user-attachments/assets/15d03bad-a57a-47d3-8a36-96dc3a703c0b"/>

# 모다
<img width="200" height="432" alt="IMG_2845" src="https://github.com/user-attachments/assets/f5cffaf9-5ea7-4e8d-84a3-95d47fe608d5" />|<img width="200" height="432" alt="IMG_2824" src="https://github.com/user-attachments/assets/5dd1f1c2-ee8a-47e7-8c1d-71edc7c3a0ac" />|<img width="200" height="432" alt="IMG_2831" src="https://github.com/user-attachments/assets/3edd53bc-b0f2-42db-9d71-9e2bffaa922e" />|<img width="200" height="432" alt="IMG_2834" src="https://github.com/user-attachments/assets/c3a2c948-634f-4516-9f00-80ad6673a88f" />|
|:-:|:-:|:-:|:-:|

|구분|내용|
|:--:|:--|
|**팀 인원**|iOS 개발 3명|
|**기획 및 개발 기간**|2025.11 - 2025.11 (3주, 핵심 개발 기간 3주)|
|**최소 지원 버전**|iOS 17.0+|

## 핵심 기능
- 소셜 로그인
- 친구 기반 물품 거래
- 지도 기반 물품 검색
- 실시간 채팅
- 카드 결제 시스템

## 기술 스택
|분류|기술 스택|
|:--:|:--|
|**UI Framework**|![SwiftUI](https://img.shields.io/badge/SwiftUI-0066FF?style=flat-square&logo=swift&logoColor=white)|
|**Architecture**|![MVI](https://img.shields.io/badge/MVI-6DB33F?style=flat-square&logo=databricks&logoColor=white) ![Combine](https://img.shields.io/badge/Combine-FA7343?style=flat-square&logo=swift&logoColor=white)|
|**Database**|![Realm](https://img.shields.io/badge/Realm-39477F?style=flat-square&logo=realm&logoColor=white)|
|**Networking**|![URLSession](https://img.shields.io/badge/URLSession-007AFF?style=flat-square&logo=apple&logoColor=white) ![SocketIO](https://img.shields.io/badge/SocketIO-010101?style=flat-square&logo=socketdotio&logoColor=white)|
|**Caching**|![NSCache](https://img.shields.io/badge/NSCache-007AFF?style=flat-square&logo=apple&logoColor=white) ![Custom_Implementation](https://img.shields.io/badge/Custom_Implementation-FF6B6B?style=flat-square)|
|**Media**|![AVFoundation](https://img.shields.io/badge/AVFoundation-007AFF?style=flat-square&logo=apple&logoColor=white) ![CoreImage](https://img.shields.io/badge/CoreImage-007AFF?style=flat-square&logo=apple&logoColor=white)|
|**Authentication**|![KakaoSDK](https://img.shields.io/badge/KakaoSDK-FFCD00?style=flat-square&logo=kakao&logoColor=black)|
|**Payment**|![iamport](https://img.shields.io/badge/iamport-5B47ED?style=flat-square)|
|**Apple Frameworks**|![MapKit](https://img.shields.io/badge/MapKit-007AFF?style=flat-square&logo=apple&logoColor=white) ![CoreLocation](https://img.shields.io/badge/CoreLocation-007AFF?style=flat-square&logo=apple&logoColor=white) ![PhotosUI](https://img.shields.io/badge/PhotosUI-007AFF?style=flat-square&logo=apple&logoColor=white)|
|**보안**|![Keychain](https://img.shields.io/badge/Keychain-007AFF?style=flat-square&logo=apple&logoColor=white) ![CryptoKit](https://img.shields.io/badge/CryptoKit-007AFF?style=flat-square&logo=apple&logoColor=white)|## 전체 구조

### MVI + Combine
- 단방향 데이터 플로우
- Combine을 활용한 반응형 시스템 구현

### Token
- Interceptor 패턴 기반 커스텀 토큰 갱신 시스템
- accessToken 만료(419) 시 refreshToken으로 자동 갱신
- Continuation 활용한 Race Condition 방지
- KeyChain 암호화 저장

### Networking
- Router 패턴 기반 타입 세이프 API 엔드포인트
- Interceptor 패턴 기반 요청/응답 가로채기 구현
- Multipart/form-data 파일 업로드
- NetworkMonitor로 실시간 연결 상태 감지
- 네트워크 불안정 시 자동 재시도 로직

### Caching System
- 메모리/디스크 이중 캐시 구조
- LRU + 시간 기반 정책(최대 7일 보관) 사용
- 스트리밍 + 백그라운드 다운로드 병행 처리
- NSCache 기반 이미지/동영상 통합 관리
- 다운샘플링으로 메모리 사용량 최적화
- Task 취소 가능
- 자동 재시도
- Actor 기반 스레드 안전성 보장
- 로그아웃/회원탈퇴 시 전체 삭제
  
#### 캐시 용량 관리 (용량 초과 시 LRU 삭제)
- 이미지 메모리 최대 50MB/디스크 최대 200MB
- 동영상 최대 230MB, 썸네일 최대 20MB

## 주요 기능
### 채팅
<img width="200" height="432" alt="IMG_2832" src="https://github.com/user-attachments/assets/4828efb6-d6cb-429e-918e-3b9f9e984cd3" />|<img width="200" height="432" alt="IMG_2824" src="https://github.com/user-attachments/assets/601ce439-6bb6-45f2-bfc3-e97ce81c0cc7" />|
|:-:|:-:|

- SocketIO 기반 실시간 메시징
- Realm 로컬 저장으로 오프라인 조회 가능
- 이미지 전송 지원
- 네트워크 끊김 시 자동 재전송, 실패시 재전송/삭제 버튼 제공

### 홈 피드
|<img width="200" height="432" alt="IMG_2846" src="https://github.com/user-attachments/assets/2ccdfb47-a635-44fd-abf4-959e3046f875" />| <img width="200" height="432" alt="IMG_2847" src="https://github.com/user-attachments/assets/7d1ec773-ac00-48ac-9079-591a2f228fe6" />|
|:-:|:-:|

- 이미지/동영상 미디어 지원
- Pinterest 스타일 2열 그리드 레이아웃
- Cursor 기반 페이지네이션
- 낙관적 UI 적용한 좋아요 기능

## 지도 검색
<img width="200" height="432" alt="IMG_2838" src="https://github.com/user-attachments/assets/3f5a0b2b-9747-4788-9aca-219614ca7808" />|<img width="200" height="432" alt="IMG_2837" src="https://github.com/user-attachments/assets/0c9eb41f-b0b3-49ca-ac5a-b5935c56e894" />|
|:-:|:-:|
- 현재 위치 기반 게시글 표시
- 줌 레벨별 클러스터링

## 상품 업로드
<img width="200" height="432" alt="IMG_2796" src="https://github.com/user-attachments/assets/0ed68f90-b9d4-40b4-84b2-26d2e01959ef" />|<img width="200" height="432" alt="IMG_2835" src="https://github.com/user-attachments/assets/eadb8d2a-833c-4508-80cb-54b0ee9f0752" />|
|:-:|:-:|
- 썸네일 사용자 선택
- Multipart/form-data 파일 업로드
- 미디어 자동 압축
  - 이미지: JPEG 품질 80% 압축
  - 동영상: 720p(1280x720) H.264 압축
- 미디어 병렬 업로드

## 상품 상세
<img width="200" height="432" alt="IMG_2847" src="https://github.com/user-attachments/assets/8ae1b4a4-19ad-4ed5-89b4-b9109652ad5a" />|<img width="200" height="432" alt="IMG_2833" src="https://github.com/user-attachments/assets/06ee7e23-0c6e-43e0-ba93-db97e3771d6f" />|
|:-:|:-:|
- 실시간 댓글 시스템
- 거래 위치 지도 표시
- Iamport 결제 연동 (PG사 연동, 결제 검증)
- 관련 상품 추천

### 프로필
|<img width="200" height="432" alt="IMG_2815" src="https://github.com/user-attachments/assets/bd527af2-31b9-4038-91cf-a1e9fe5847dd" />|<img width="200" height="432" alt="IMG_2840" src="https://github.com/user-attachments/assets/943d3a66-eb9f-49b0-95ab-41fbdd564279" />|
|:-:|:-:|
- Realm 기반 Offline-First 전략으로 로컬 즉시 로드 후 서버 동기화
- 주요 액션 시 자동 동기화, 로그아웃 시 전체 삭제
