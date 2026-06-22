# PuttAI 프로젝트

## 프로젝트 개요
아이폰 Pro LiDAR 기반 골프 퍼팅 보조 앱
React Native + Expo로 개발
윈도우 환경에서 개발, 아이폰 Pro에서 Expo Go로 테스트

## 핵심 기능
- LiDAR로 핀까지 거리 측정
- 자이로스코프로 경사 감지
- Claude API로 브레이크 방향 추천
- 출력 예시: "7.8m / 약한 오르막 / 1컵 우측"

## 기술 스택
- React Native + Expo
- expo-camera (LiDAR)
- expo-sensors (자이로스코프)
- Anthropic Claude API

## 개발 환경
- 윈도우 PC에서 개발
- 아이폰 12 Pro 이상에서만 작동 (LiDAR 필수)
- Expo Go로 테스트

## 주의사항
- LiDAR는 아이폰 Pro 전용
- 골프 퍼팅 용도 특화
