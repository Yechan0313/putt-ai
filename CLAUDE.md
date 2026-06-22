# PuttAI 프로젝트

## 프로젝트 개요
아이폰 Pro LiDAR 기반 골프 퍼팅 보조 앱
**Pure Swift + SwiftUI + ARKit** (Expo/React Native 제거)

## 핵심 기능
- ARKit LiDAR로 핀까지 거리 측정 (sceneDepth 중앙 픽셀)
- CoreMotion 가속도계로 경사 감지 (pitch/roll)
- 브레이크 방향 자동 계산
- 출력 예시: "7.8m / 약한 오르막 / 1컵 우측"

## 기술 스택
- Swift 5 + SwiftUI
- ARKit (ARWorldTrackingConfiguration + .sceneDepth)
- CoreMotion (CMMotionManager 가속도계)
- xcodegen (CI에서 Xcode 프로젝트 자동 생성)

## 파일 구조
```
Sources/
  PuttAIApp.swift     - @main 진입점
  ContentView.swift   - 전체 UI (AR카메라 + 오버레이)
  ARManager.swift     - ARKit LiDAR 거리 측정
  PuttViewModel.swift - 비즈니스 로직 + CoreMotion
  Info.plist          - 권한 설정
project.yml           - xcodegen 설정
```

## CI 빌드 흐름 (GitHub Actions macos-15)
1. xcodegen generate → PuttAI.xcodeproj 생성
2. xcodebuild -sdk iphoneos (서명 없음)
3. .ipa 패키징 → Artifact 업로드

## 주의사항
- LiDAR는 iPhone 12 Pro 이상 필수
- PuttAI.xcodeproj는 .gitignore (CI에서 생성됨)
- CocoaPods / npm 없음
