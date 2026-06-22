import { useEffect, useState } from 'react';
import {
  Platform,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { CameraView, useCameraPermissions } from 'expo-camera';
import { Accelerometer } from 'expo-sensors';
import {
  addDistanceListener,
  isLidarSupported,
  isModuleAvailable,
  startLidarSession,
  stopLidarSession,
} from 'lidar-sensor';
import type { Subscription } from 'expo-modules-core';

type Vec3 = { x: number; y: number; z: number };

export default function App() {
  const [permission, requestPermission] = useCameraPermissions();
  const [accel, setAccel] = useState<Vec3>({ x: 0, y: 0, z: 0 });
  const [distance, setDistance] = useState<number | null>(null);
  const [lidarState, setLidarState] = useState<
    'loading' | 'unavailable' | 'unsupported' | 'running' | 'error'
  >('loading');
  const [errorMsg, setErrorMsg] = useState('');

  // 자이로스코프
  useEffect(() => {
    const sub = Accelerometer.addListener((d) => setAccel(d));
    Accelerometer.setUpdateInterval(50);
    return () => sub.remove();
  }, []);

  // LiDAR 세션
  useEffect(() => {
    if (!isModuleAvailable()) {
      setLidarState('unavailable');
      return;
    }
    if (!isLidarSupported()) {
      setLidarState('unsupported');
      return;
    }

    let distSub: Subscription | null = null;

    startLidarSession()
      .then(() => {
        setLidarState('running');
        distSub = addDistanceListener((m) => setDistance(m));
      })
      .catch((e: Error) => {
        setLidarState('error');
        setErrorMsg(e.message);
      });

    return () => {
      distSub?.remove();
      stopLidarSession();
    };
  }, []);

  const slopeDeg = Math.atan2(-accel.y, Math.abs(accel.z)) * (180 / Math.PI);
  const latDeg   = Math.atan2( accel.x, Math.abs(accel.z)) * (180 / Math.PI);

  const slopeText = () => {
    if (Math.abs(slopeDeg) < 1.5) return '평지';
    return slopeDeg > 0
      ? `오르막 ${slopeDeg.toFixed(1)}°`
      : `내리막 ${Math.abs(slopeDeg).toFixed(1)}°`;
  };
  const latText = () => {
    if (Math.abs(latDeg) < 1.5) return '수평';
    return latDeg > 0
      ? `우측경사 ${latDeg.toFixed(1)}°`
      : `좌측경사 ${Math.abs(latDeg).toFixed(1)}°`;
  };

  const distDisplay = () => {
    if (lidarState === 'unavailable') return { text: '— m', sub: 'Dev Client 빌드 필요' };
    if (lidarState === 'unsupported') return { text: '— m', sub: 'LiDAR 미지원 기기' };
    if (lidarState === 'error')       return { text: '— m', sub: errorMsg };
    if (lidarState === 'loading')     return { text: '— m', sub: 'LiDAR 초기화 중...' };
    if (distance === null)            return { text: '— m', sub: '측정 중...' };
    return { text: `${distance.toFixed(2)} m`, sub: '화면 중앙까지 거리' };
  };

  if (!permission) return <View style={s.container} />;

  if (!permission.granted) {
    return (
      <View style={[s.container, s.center]}>
        <Text style={s.permMsg}>카메라 권한이 필요합니다</Text>
        <TouchableOpacity style={s.permBtn} onPress={requestPermission}>
          <Text style={s.permBtnTxt}>권한 허용</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const dd = distDisplay();
  const lidarOk = lidarState === 'running';

  return (
    <View style={s.container}>
      <CameraView style={s.camera} facing="back">
        <View style={s.overlay}>

          {/* 상단 상태 배지 */}
          <View style={s.topBar}>
            <Badge label="카메라" ok={permission.granted} okText="ON" failText="OFF" />
            <Badge label="자이로"  ok={accel.x !== 0}      okText="ON" failText="대기" />
            <Badge label="LiDAR"  ok={lidarOk}            okText="ON"
              failText={lidarState === 'unavailable' ? 'Dev Client' : lidarState === 'unsupported' ? '미지원' : '오류'} />
          </View>

          {/* 조준선 */}
          <View style={s.xhairWrap}>
            <View style={s.xhH} />
            <View style={s.xhV} />
            <View style={s.xhCircle} />
          </View>

          {/* 하단 정보 패널 */}
          <View style={s.panel}>
            <View style={s.distRow}>
              <Text style={s.distLabel}>거리</Text>
              <View style={s.distRight}>
                <Text style={[s.distValue, !lidarOk && s.distDim]}>{dd.text}</Text>
                <Text style={[s.distSub, lidarOk && s.distSubOk]}>{dd.sub}</Text>
              </View>
            </View>

            <View style={s.divider} />

            <Row label="경사"  value={slopeText()} />
            <Row label="횡경사" value={latText()} />

            <View style={s.divider} />

            <Row
              label="가속계"
              value={`X${accel.x.toFixed(2)}  Y${accel.y.toFixed(2)}  Z${accel.z.toFixed(2)}`}
              small
            />

            {lidarState === 'unavailable' && (
              <View style={s.noteBox}>
                <Text style={s.noteText}>
                  {'⚠️  LiDAR 거리 측정은 EAS Dev Client 빌드 후 사용 가능\n'}
                  {'     eas build --profile development --platform ios'}
                </Text>
              </View>
            )}
          </View>

        </View>
      </CameraView>
    </View>
  );
}

// ── 서브 컴포넌트 ──────────────────────────────────────────

function Badge({ label, ok, okText, failText }: {
  label: string; ok: boolean; okText: string; failText: string;
}) {
  return (
    <View style={[s.badge, { borderColor: ok ? GREEN : RED }]}>
      <Text style={s.badgeLabel}>{label}</Text>
      <Text style={[s.badgeVal, { color: ok ? GREEN : RED }]}>
        {ok ? okText : failText}
      </Text>
    </View>
  );
}

function Row({ label, value, small }: { label: string; value: string; small?: boolean }) {
  return (
    <View style={s.row}>
      <Text style={small ? s.rowLblSm : s.rowLbl}>{label}</Text>
      <Text style={small ? s.rowValSm : s.rowVal}>{value}</Text>
    </View>
  );
}

// ── 스타일 ──────────────────────────────────────────────────

const GREEN = '#00FF88';
const RED   = '#FF6B6B';
const DIM   = 'rgba(255,255,255,0.08)';

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000' },
  center:    { alignItems: 'center', justifyContent: 'center' },
  camera:    { flex: 1 },
  overlay:   { flex: 1, justifyContent: 'space-between' },

  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingTop: Platform.OS === 'ios' ? 58 : 36,
    paddingHorizontal: 12,
    paddingBottom: 8,
    backgroundColor: 'rgba(0,0,0,0.45)',
  },
  badge: {
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 6,
    minWidth: 86,
  },
  badgeLabel: { color: '#888', fontSize: 11, marginBottom: 2 },
  badgeVal:   { fontSize: 12, fontWeight: '700' },

  xhairWrap:  { flex: 1, alignItems: 'center', justifyContent: 'center' },
  xhH:        { position: 'absolute', width: 72, height: 1.5, backgroundColor: GREEN, opacity: 0.75 },
  xhV:        { position: 'absolute', width: 1.5, height: 72, backgroundColor: GREEN, opacity: 0.75 },
  xhCircle:   { width: 28, height: 28, borderRadius: 14, borderWidth: 1.5, borderColor: GREEN, opacity: 0.75 },

  panel: {
    backgroundColor: 'rgba(0,0,0,0.78)',
    marginHorizontal: 14,
    marginBottom: 36,
    borderRadius: 18,
    padding: 18,
    borderWidth: 1,
    borderColor: 'rgba(0,255,136,0.22)',
  },
  distRow:  { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 6 },
  distLabel:{ color: '#777', fontSize: 15 },
  distRight:{ alignItems: 'flex-end' },
  distValue:{ color: '#FFF', fontSize: 32, fontWeight: '700' },
  distDim:  { color: '#555' },
  distSub:  { color: '#FF6B6B', fontSize: 11, marginTop: 2 },
  distSubOk:{ color: '#00CC66' },

  row:     { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 8 },
  rowLbl:  { color: '#777', fontSize: 15 },
  rowVal:  { color: '#FFF', fontSize: 16, fontWeight: '600' },
  rowLblSm:{ color: '#555', fontSize: 12 },
  rowValSm:{ color: '#777', fontSize: 12 },
  divider: { height: 1, backgroundColor: DIM, marginVertical: 4 },

  noteBox: {
    marginTop: 12,
    padding: 10,
    backgroundColor: 'rgba(255,165,0,0.12)',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(255,165,0,0.28)',
  },
  noteText:{ color: '#FFA500', fontSize: 11.5, lineHeight: 18 },

  permMsg:   { color: '#FFF', fontSize: 18, marginBottom: 24, textAlign: 'center', paddingHorizontal: 24 },
  permBtn:   { backgroundColor: GREEN, paddingHorizontal: 32, paddingVertical: 14, borderRadius: 12 },
  permBtnTxt:{ color: '#000', fontSize: 16, fontWeight: '700' },
});
