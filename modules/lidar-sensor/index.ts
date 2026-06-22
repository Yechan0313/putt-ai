import { EventEmitter, requireNativeModule } from 'expo-modules-core';
import { Platform } from 'react-native';
import type { Subscription } from 'expo-modules-core';

type DistanceEvent = { distance: number };

// Expo Go에서는 네이티브 모듈 로드 실패 → null 처리
let _mod: ReturnType<typeof requireNativeModule> | null = null;
let _emitter: EventEmitter | null = null;

if (Platform.OS === 'ios') {
  try {
    _mod = requireNativeModule('LidarSensor');
    _emitter = new EventEmitter(_mod);
  } catch {
    // Expo Go 환경 — Dev Client 빌드 필요
  }
}

/** 현재 기기가 LiDAR를 지원하는지 여부 */
export function isLidarSupported(): boolean {
  try {
    return _mod?.isSupported() ?? false;
  } catch {
    return false;
  }
}

/** LiDAR 네이티브 모듈이 로드됐는지 여부 (Expo Go vs Dev Client 구분용) */
export function isModuleAvailable(): boolean {
  return _mod !== null;
}

/** ARKit SceneDepth 세션 시작 */
export async function startLidarSession(): Promise<void> {
  if (!_mod) throw new Error('LiDAR 모듈 없음 — Dev Client 빌드가 필요합니다');
  return _mod.startSession();
}

/** ARKit 세션 중단 */
export function stopLidarSession(): void {
  _mod?.stopSession();
}

/**
 * 화면 중앙 거리(미터)를 실시간으로 수신하는 리스너 등록.
 * Expo Go에서는 null을 반환합니다.
 */
export function addDistanceListener(
  cb: (meters: number) => void
): Subscription | null {
  if (!_emitter) return null;
  return _emitter.addListener<DistanceEvent>('onDistanceUpdate', (e) => cb(e.distance));
}
