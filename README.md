<img width="100" src="https://github.com/user-attachments/assets/15d03bad-a57a-47d3-8a36-96dc3a703c0b"/>

# 모다
<img width="200" height="432" alt="IMG_2848 2" src="https://github.com/user-attachments/assets/ad6fb05d-15c9-4178-b202-6bae09b37d57" />| <img width="200" height="432" alt="IMG_2845" src="https://github.com/user-attachments/assets/f5cffaf9-5ea7-4e8d-84a3-95d47fe608d5" />|<img width="200" height="432" alt="IMG_2850" src="https://github.com/user-attachments/assets/57c08c88-bb32-4e2a-9fcb-27cf5111414f" />|<img width="200" height="432" alt="IMG_2834" src="https://github.com/user-attachments/assets/c3a2c948-634f-4516-9f00-80ad6673a88f" />|
|:-:|:-:|:-:|:-:|

|구분|내용|
|:--:|:--|
|**팀 인원**|iOS 개발 3명, 백엔드 1명|
|**기획 및 개발 기간**|2025.11 - 2025.11 (3주, 핵심 개발 기간 3주)|
|**최소 지원 버전**|iOS 17.0+|

## 핵심 기능
- 친구 기반 물품 거래
- 이미지/ 동영상 물품 정보 입력
- 지도 기반 물품 검색
- 실시간 1: 1 채팅
- 카드 결제 (PG 결제)

## 기술 스택
|분류|기술 스택|
|:--:|:--|
|**UI Framework**|![SwiftUI](https://img.shields.io/badge/SwiftUI-0066FF?style=flat-square&logo=swift&logoColor=white)|
|**Architecture**|![MVI](https://img.shields.io/badge/MVI-6DB33F?style=flat-square&logo=databricks&logoColor=white) ![Combine](https://img.shields.io/badge/Combine-FA7343?style=flat-square&logo=swift&logoColor=white)|
|**Database**|![Realm](https://img.shields.io/badge/Realm-39477F?style=flat-square&logo=realm&logoColor=white)|
|**Networking**|![URLSession](https://img.shields.io/badge/URLSession-007AFF?style=flat-square&logo=apple&logoColor=white) ![SocketIO](https://img.shields.io/badge/SocketIO-010101?style=flat-square&logo=socketdotio&logoColor=white)|
|**Caching**|![NSCache](https://img.shields.io/badge/NSCache-007AFF?style=flat-square&logo=apple&logoColor=white) ![Custom_Implementation](https://img.shields.io/badge/Custom_Implementation-FF6B6B?style=flat-square)|
|**Authentication**|![KakaoSDK](https://img.shields.io/badge/KakaoSDK-FFCD00?style=flat-square&logo=kakao&logoColor=black)|
|**Payment**|![iamport](https://img.shields.io/badge/iamport-5B47ED?style=flat-square)|
|**Apple Frameworks**|![MapKit](https://img.shields.io/badge/MapKit-007AFF?style=flat-square&logo=apple&logoColor=white) ![CoreLocation](https://img.shields.io/badge/CoreLocation-007AFF?style=flat-square&logo=apple&logoColor=white) ![PhotosUI](https://img.shields.io/badge/PhotosUI-007AFF?style=flat-square&logo=apple&logoColor=white) ![AVFoundation](https://img.shields.io/badge/AVFoundation-007AFF?style=flat-square&logo=apple&logoColor=white) ![CoreImage](https://img.shields.io/badge/CoreImage-007AFF?style=flat-square&logo=apple&logoColor=white)|
|**보안**|![Keychain](https://img.shields.io/badge/Keychain-007AFF?style=flat-square&logo=apple&logoColor=white) ![CryptoKit](https://img.shields.io/badge/CryptoKit-007AFF?style=flat-square&logo=apple&logoColor=white)|## 전체 구조
|**광고**|![Google AdMob](https://img.shields.io/badge/Google_AdMob-EA4335?style=flat-square&logo=google&logoColor=white)

### MVI + Combine
- 코드를 Store, Intent, State, View로 분리하여 MVI 단방향 플로우 구현
- Combine을 활용한 반응형 시스템 구현

### Networking
#### Interceptor 패턴 기반 커스텀 토큰(JWT) 갱신 시스템
- accessToken 만료(419) 시 refreshToken으로 자동 갱신
- Continuation 활용한 Race Condition 방지
- 토큰 Keychain 암호화 저장
  
#### Router 패턴 기반 API Endpoint
- Multipart/form-data 파일 업로드(이미지, 동영상)
- NetworkMonitor로 실시간 연결 상태 감지 및 네트워크 불안정 시 클라이언트 에러 자동 재시도

### Caching System
- 이미지, 동영상을 메모리(NSCache) + 디스크 캐싱(FileManager)로 구현
- 비디오 메타데이터 캐싱 지원
- 동영상 스트리밍 + 캐시 백그라운드 다운로드 병행 처리
- 다운샘플링으로 메모리 사용 최적화
- 화면 전환 시 캐싱 취소 및 자동 재시도

## 주요 기능
### 채팅
<img width="200" height="432" alt="IMG_2832" src="https://github.com/user-attachments/assets/4828efb6-d6cb-429e-918e-3b9f9e984cd3" />|<img width="200" height="432" alt="IMG_2850" src="https://github.com/user-attachments/assets/abf873b8-945e-443c-a468-5c5ffe611286" />|
|:-:|:-:|

- 오프라인에서도 이전 채팅 내역 조회
- 이미지 전송
- 네트워크 끊김 시 자동 재전송
- 실패 시 재전송/삭제 버튼 제공

### 홈 피드
|<img width="200" height="432" alt="IMG_2846" src="https://github.com/user-attachments/assets/2ccdfb47-a635-44fd-abf4-959e3046f875" />| <img width="200" height="432" alt="IMG_2847" src="https://github.com/user-attachments/assets/7d1ec773-ac00-48ac-9079-591a2f228fe6" />|
|:-:|:-:|

- 이미지 / 동영상 지원
- 동영상 자동 재생(206 partial content)
- cursor 기반 페이지네이션
- 좋아요 기능(낙관적 UI)
- 구글 AdMob 광고

### 지도 검색
<img width="200" height="432" alt="IMG_2838" src="https://github.com/user-attachments/assets/3f5a0b2b-9747-4788-9aca-219614ca7808" />|<img width="200" height="432" alt="IMG_2837" src="https://github.com/user-attachments/assets/0c9eb41f-b0b3-49ca-ac5a-b5935c56e894" />|
|:-:|:-:|
- 현재 위치 기반 게시글 표시
- 줌 레벨별 클러스터링

### 상품 업로드
<img width="200" height="432" alt="IMG_2796" src="https://github.com/user-attachments/assets/0ed68f90-b9d4-40b4-84b2-26d2e01959ef" />|<img width="200" height="432" alt="IMG_2835" src="https://github.com/user-attachments/assets/eadb8d2a-833c-4508-80cb-54b0ee9f0752" />|
|:-:|:-:|
- 이미지 / 동영상 업로드 지원(Multipart/form-data)
- 썸네일 선택 지원
- 업로드 시 이미지 / 동영상 자동 압축

### 상품 상세
<img width="200" height="432" alt="IMG_2847" src="https://github.com/user-attachments/assets/8ae1b4a4-19ad-4ed5-89b4-b9109652ad5a" />|<img width="200" height="432" alt="IMG_2833" src="https://github.com/user-attachments/assets/06ee7e23-0c6e-43e0-ba93-db97e3771d6f" />|
|:-:|:-:|
- 상품 정보 불러오기
- 댓글 시스템
- 거래 위치 지도 표시
- 관련 상품 추천
- PG사 결제 및 영수증 검증

### 프로필
|<img width="200" height="432" alt="IMG_2815" src="https://github.com/user-attachments/assets/bd527af2-31b9-4038-91cf-a1e9fe5847dd" />|<img width="200" height="432" alt="IMG_2840" src="https://github.com/user-attachments/assets/943d3a66-eb9f-49b0-95ab-41fbdd564279" />|
|:-:|:-:|
- 오프라인 환경에서 프로필/친구 목록 조회
- 로그아웃 시 전체 데이터 삭제
