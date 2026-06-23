# ── Fix protobuf / MessageFactory conflict ───────────────────────────────────
try:
    from google.protobuf import message_factory as _mf
    if not hasattr(_mf.MessageFactory, "GetPrototype"):
        def _get_prototype(self, descriptor):
            return self._classes.get(descriptor)
        _mf.MessageFactory.GetPrototype = _get_prototype
        print("[PATCH] MessageFactory.GetPrototype OK")
except Exception as _e:
    print(f"[PATCH] warning: {_e}")
# ─────────────────────────────────────────────────────────────────────────────

import cv2
import mediapipe as mp
import threading
import time
import math
import requests
import os
from collections import deque
from enum import Enum
from flask import Flask, Response, request, jsonify
from flask_cors import CORS

# Firebase Admin SDK
try:
    import firebase_admin
    from firebase_admin import credentials, db as firebase_db
    _FIREBASE_OK = True
except ImportError:
    _FIREBASE_OK = False
    print("[FIREBASE] Chưa cài — chạy: pip install firebase-admin")

# ════════════════════════════════════════════════════════
#  CONFIG
# ════════════════════════════════════════════════════════

BOT_TOKEN = "8981707645:AAHEGZ0f1e5lmGpDUxfl-SfVMsrLP8Xu6zE"
CHAT_ID   = "1504325061"
TG_BASE   = f"https://api.telegram.org/bot{BOT_TOKEN}"

FIREBASE_CRED = os.getenv("FIREBASE_CRED", "serviceAccountKey.json")
FIREBASE_URL  = os.getenv("FIREBASE_URL",
    "https://fall-detection-nonti-default-rtdb.firebaseio.com/")

FB_STATUS_INTERVAL  = 2.0
FB_HISTORY_INTERVAL = 10.0

FRAME_W = 320
FRAME_H = 240

# ── Tốc độ & tải CPU ──
FPS             = 15
STREAM_FPS      = 5
MAX_CLIENTS     = 2
PROCESS_EVERY_N = 3
JPEG_QUALITY    = 55
POSE_COMPLEXITY = 1     # 1 = z chính xác hơn (bắt ngã Oz tốt). Pi nặng -> 0.

# ── Cửa sổ thời gian & giữ trạng thái ──
PENDING_WINDOW      = 10.0    # fallFlag -> chờ vision xác nhận trong 10s
FALSE_ALARM_HOLD    = 2.0
FALL_CONFIRMED_HOLD = 15.0
ALERT_COOLDOWN      = 30.0    # cooldown Telegram cho té ngã
VITALS_COOLDOWN     = 60.0    # cooldown Telegram cho cảnh báo sinh hiệu
SOS_HOLD            = 30.0    # giữ trạng thái SOS sau 1 lần nhấn (giây)

FALL_FRAMES_NEEDED  = 3
STAND_FRAMES_NEEDED = 5
POSTURE_THRESHOLD   = 0.55

ANGLE_STAND = 30.0      # < 30° coi như đứng
ANGLE_LIE   = 60.0      # > 60° coi như nằm

# ── Ngưỡng sinh hiệu ──
HR_LOW        = 50      # < 50 -> cảnh báo
HR_HIGH       = 120     # > 120 -> cảnh báo
SPO2_CRITICAL = 90      # < 90 -> cảnh báo

MAX_HISTORY = 120

# ════════════════════════════════════════════════════════
#  STATE MACHINE
# ════════════════════════════════════════════════════════

class State(Enum):
    IDLE           = "IDLE"
    PENDING        = "PENDING"
    FALL_CONFIRMED = "FALL_CONFIRMED"
    FALSE_ALARM    = "FALSE_ALARM"

# ════════════════════════════════════════════════════════
#  SHARED STATE
# ════════════════════════════════════════════════════════

app = Flask(__name__)
CORS(app)

frame_lock   = threading.Lock()
state_lock   = threading.Lock()
output_frame = None

health = {
    "heart_rate": 0,
    "spo2":       0,
    "steps":      0,
    "fall_flag":  False,
    "sos":        False,
}

system_state     = State.IDLE
current_alert     = "NORMAL"
fall_status       = False
state_entered     = time.time()

last_alert_time   = 0.0
last_alert_level  = ''
last_vitals_alert = 0.0

_prev_sos  = False
_sos_until = 0.0       # SOS giữ tới thời điểm này

hr_history:   deque = deque(maxlen=MAX_HISTORY)
spo2_history: deque = deque(maxlen=MAX_HISTORY)
pose_hip_history: deque = deque(maxlen=10)

_last_fb_status  = 0.0
_last_fb_history = 0.0
_stream_clients  = 0
_stream_lock     = threading.Lock()
_stop_camera     = False

# ════════════════════════════════════════════════════════
#  FIREBASE
# ════════════════════════════════════════════════════════

_fb_ref = None

def init_firebase():
    global _fb_ref
    if not _FIREBASE_OK:
        return
    if not os.path.exists(FIREBASE_CRED):
        print(f"[FIREBASE] File không tồn tại: {FIREBASE_CRED}")
        return
    try:
        cred = credentials.Certificate(FIREBASE_CRED)
        firebase_admin.initialize_app(cred, {"databaseURL": FIREBASE_URL})
        _fb_ref = firebase_db.reference("fall_detection")
        _fb_ref.child("system").set({
            "started_at": int(time.time()),
            "status": "online",
        })
        print("[FIREBASE] Kết nối thành công ✓")
    except Exception as e:
        print(f"[FIREBASE] Lỗi: {e}")


def fb_push_status():
    global _last_fb_status
    now = time.time()
    if _fb_ref is None or (now - _last_fb_status) < FB_STATUS_INTERVAL:
        return
    _last_fb_status = now
    try:
        _fb_ref.child("status").set({
            "heart_rate":    health["heart_rate"],
            "spo2":          health["spo2"],
            "steps":         health["steps"],
            "fall_flag":     health["fall_flag"],
            "sos":           is_sos_active(),
            "fall_detected": fall_status,
            "alert":         current_alert,
            "state":         system_state.value,
            "timestamp":     int(now),
        })
    except Exception as e:
        print(f"[FIREBASE] push status lỗi: {e}")


def fb_push_history():
    global _last_fb_history
    now = time.time()
    if _fb_ref is None or (now - _last_fb_history) < FB_HISTORY_INTERVAL:
        return
    _last_fb_history = now
    try:
        _fb_ref.child("history").set({
            "heart_rate": [p["v"] for p in hr_history],
            "spo2":       [p["v"] for p in spo2_history],
            "timestamps": [p["t"] for p in hr_history],
        })
    except Exception as e:
        print(f"[FIREBASE] push history lỗi: {e}")


def fb_push_event(alert: str, hr: int, spo2: int, steps: int):
    """Đẩy 1 sự kiện (FALL / SOS) lên node fall_events."""
    if _fb_ref is None:
        return
    try:
        _fb_ref.child("fall_events").push({
            "alert":      alert,
            "heart_rate": hr,
            "spo2":       spo2,
            "steps":      steps,
            "timestamp":  int(time.time()),
        })
        print(f"[FIREBASE] Event '{alert}' pushed ✓")
    except Exception as e:
        print(f"[FIREBASE] push event lỗi: {e}")


def firebase_loop():
    """1 thread nền duy nhất — đẩy status/history theo chu kỳ."""
    while True:
        fb_push_status()
        fb_push_history()
        time.sleep(1.0)

# ════════════════════════════════════════════════════════
#  MEDIAPIPE
# ════════════════════════════════════════════════════════

mp_pose = mp.solutions.pose
mp_draw = mp.solutions.drawing_utils

pose = mp_pose.Pose(
    model_complexity=POSE_COMPLEXITY,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5,
)

LANDMARK_STYLE   = mp_draw.DrawingSpec(color=(0, 255, 255), thickness=2, circle_radius=3)
CONNECTION_STYLE = mp_draw.DrawingSpec(color=(0, 200, 255), thickness=2)

# ════════════════════════════════════════════════════════
#  CAMERA
# ════════════════════════════════════════════════════════

def open_camera():
    c = cv2.VideoCapture(0, cv2.CAP_V4L2)
    c.set(cv2.CAP_PROP_FRAME_WIDTH,  FRAME_W)
    c.set(cv2.CAP_PROP_FRAME_HEIGHT, FRAME_H)
    c.set(cv2.CAP_PROP_FPS,          FPS)
    try:
        c.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    except Exception:
        pass
    return c

cap = open_camera()
print(f"[CAM] opened={cap.isOpened()}")

# ════════════════════════════════════════════════════════
#  TELEGRAM
# ════════════════════════════════════════════════════════

def _tg_send(text: str):
    try:
        r = requests.post(
            f"{TG_BASE}/sendMessage",
            json={"chat_id": CHAT_ID, "text": text, "parse_mode": "HTML"},
            timeout=8,
        )
        print(f"[TG] msg {r.status_code}")
    except Exception as e:
        print(f"[TG] err: {e}")


def _tg_photo(frame_copy, caption: str):
    try:
        path = "/tmp/fall_alert.jpg"
        cv2.imwrite(path, frame_copy)
        with open(path, "rb") as f:
            r = requests.post(
                f"{TG_BASE}/sendPhoto",
                data={"chat_id": CHAT_ID, "caption": caption},
                files={"photo": f},
                timeout=12,
            )
        print(f"[TG] photo {r.status_code}")
    except Exception as e:
        print(f"[TG] photo err: {e}")


def _grab_frame():
    with frame_lock:
        return None if output_frame is None else output_frame.copy()


def tg_fall_alert(frame_copy, hr: int, spo2: int, level: str):
    icon = "🚨" if level == "CRITICAL" else "⚠️"
    msg  = (
        f"{icon} <b>FALL DETECTED — {level}</b>\n"
        f"HR    : {hr} bpm\n"
        f"SpO2  : {spo2}%\n"
        f"Steps : {health['steps']}\n"
        f"Time  : {time.strftime('%H:%M:%S')}"
    )
    threading.Thread(target=_tg_send,  args=(msg,),                  daemon=True).start()
    if frame_copy is not None:
        threading.Thread(target=_tg_photo, args=(frame_copy, msg[:200]), daemon=True).start()


def tg_sos_alert(hr: int, spo2: int):
    msg = (
        f"🆘 <b>SOS — NÚT KHẨN CẤP</b>\n"
        f"Bệnh nhân yêu cầu trợ giúp NGAY!\n"
        f"HR    : {hr} bpm\n"
        f"SpO2  : {spo2}%\n"
        f"Steps : {health['steps']}\n"
        f"Time  : {time.strftime('%H:%M:%S')}"
    )
    threading.Thread(target=_tg_send, args=(msg,), daemon=True).start()
    f = _grab_frame()
    if f is not None:
        threading.Thread(target=_tg_photo, args=(f, msg[:200]), daemon=True).start()


def tg_vitals_alert(hr: int, spo2: int):
    parts = []
    if hr > 0 and (hr < HR_LOW or hr > HR_HIGH):
        parts.append(f"HR {hr} bpm")
    if spo2 > 0 and spo2 < SPO2_CRITICAL:
        parts.append(f"SpO2 {spo2}%")
    detail = ", ".join(parts) if parts else "sinh hiệu bất thường"
    msg = (
        f"⚠️ <b>CẢNH BÁO SINH HIỆU</b>\n"
        f"{detail}\n"
        f"Time : {time.strftime('%H:%M:%S')}"
    )
    threading.Thread(target=_tg_send, args=(msg,), daemon=True).start()


def tg_false_alarm():
    threading.Thread(
        target=_tg_send, args=("✅ False alarm — patient is OK",), daemon=True,
    ).start()

# ════════════════════════════════════════════════════════
#  ALERT LOGIC
# ════════════════════════════════════════════════════════

def is_sos_active() -> bool:
    return health["sos"] or time.time() < _sos_until


def _vitals_bad(hr: int, spo2: int) -> bool:
    bad_hr   = hr   > 0 and (hr < HR_LOW or hr > HR_HIGH)
    bad_spo2 = spo2 > 0 and (spo2 < SPO2_CRITICAL)
    return bad_hr or bad_spo2


def refresh_alert():
    """Nguồn sự thật duy nhất cho current_alert — tính theo thứ tự ưu tiên."""
    global current_alert
    hr   = health["heart_rate"]
    spo2 = health["spo2"]

    if is_sos_active():
        current_alert = "SOS"
    elif system_state == State.FALL_CONFIRMED:
        current_alert = "CRITICAL" if _vitals_bad(hr, spo2) else "WARNING"
    elif system_state == State.PENDING:
        current_alert = "CHECKING"
    elif system_state == State.FALSE_ALARM:
        current_alert = "FALSE_ALARM"
    elif _vitals_bad(hr, spo2):
        current_alert = "WARNING"
    else:
        current_alert = "NORMAL"

# ════════════════════════════════════════════════════════
#  STATE MACHINE
# ════════════════════════════════════════════════════════

def transition(new_state: State):
    global system_state, state_entered, fall_status
    with state_lock:
        system_state  = new_state
        state_entered = time.time()
        fall_status   = (new_state == State.FALL_CONFIRMED)
    refresh_alert()
    print(f"[FSM] -> {new_state.value}  alert={current_alert}")


def update_fsm(vision_fall: bool, vision_standing: bool):
    """Quản lý vòng đời té ngã. Té = fallFlag(sốc) -> PENDING -> vision xác nhận.
    (Không có nhánh vision-only: bắt buộc kết hợp fallFlag theo yêu cầu.)"""
    elapsed = time.time() - state_entered

    if system_state == State.PENDING:
        if vision_fall:                            # sốc + vision = té thật
            transition(State.FALL_CONFIRMED)
        elif vision_standing and elapsed > 1.0:    # vẫn đứng -> báo nhầm
            transition(State.FALSE_ALARM)
            tg_false_alarm()
        elif elapsed > PENDING_WINDOW:             # quá 10s không thấy té
            transition(State.FALSE_ALARM)

    elif system_state == State.FALL_CONFIRMED:
        if vision_standing:                        # đứng dậy -> hết
            transition(State.IDLE)
        elif elapsed > FALL_CONFIRMED_HOLD:
            transition(State.IDLE)

    elif system_state == State.FALSE_ALARM:
        if elapsed > FALSE_ALARM_HOLD:
            transition(State.IDLE)

    # IDLE: chỉ vào PENDING qua fallFlag (xử lý trong _handle_sensor_data).

# ════════════════════════════════════════════════════════
#  POSE ANALYSIS  (3D — bất biến hướng ngã)
# ════════════════════════════════════════════════════════

def _avg_world(w, a, b, axis):
    return (getattr(w[a], axis) + getattr(w[b], axis)) / 2.0


def analyze_pose(results) -> tuple:
    """(score, debug) — score [0..1], cao = giống ngã.
       orient[3D] góc nghiêng thân (Ox+Oz) | collapse[3D] | velocity | fallback 2D."""
    lm2d = results.pose_landmarks
    if not lm2d:
        pose_hip_history.clear()
        return 0.0, {}

    PL   = mp_pose.PoseLandmark
    lm   = lm2d.landmark
    nose = lm[PL.NOSE]
    lhip = lm[PL.LEFT_HIP]
    rhip = lm[PL.RIGHT_HIP]

    if nose.visibility < 0.4 or lhip.visibility < 0.4 or rhip.visibility < 0.4:
        pose_hip_history.clear()
        return 0.0, {}

    hip_y = (lhip.y + rhip.y) / 2.0
    pose_hip_history.append(hip_y)
    score_velocity = 0.0
    if len(pose_hip_history) >= 5:
        delta = pose_hip_history[-1] - pose_hip_history[-5]
        score_velocity = min(1.0, max(0.0, delta / 0.18))

    wlm = getattr(results, "pose_world_landmarks", None)

    angle_deg    = -1.0
    score_orient = None
    if wlm is not None:
        w = wlm.landmark
        vx = _avg_world(w, PL.LEFT_SHOULDER, PL.RIGHT_SHOULDER, 'x') - \
             _avg_world(w, PL.LEFT_HIP,      PL.RIGHT_HIP,      'x')
        vy = _avg_world(w, PL.LEFT_SHOULDER, PL.RIGHT_SHOULDER, 'y') - \
             _avg_world(w, PL.LEFT_HIP,      PL.RIGHT_HIP,      'y')
        vz = _avg_world(w, PL.LEFT_SHOULDER, PL.RIGHT_SHOULDER, 'z') - \
             _avg_world(w, PL.LEFT_HIP,      PL.RIGHT_HIP,      'z')
        vertical   = abs(vy)
        horizontal = math.hypot(vx, vz)
        angle_deg  = math.degrees(math.atan2(horizontal, vertical))
        score_orient = min(1.0, max(
            0.0, (angle_deg - ANGLE_STAND) / (ANGLE_LIE - ANGLE_STAND)))

    if score_orient is None:
        gap = hip_y - nose.y
        score_orient = max(0.0, 1.0 - gap / 0.20)

    score_collapse = 0.0
    if wlm is not None:
        w = wlm.landmark
        ids = [PL.NOSE,
               PL.LEFT_SHOULDER, PL.RIGHT_SHOULDER,
               PL.LEFT_HIP,      PL.RIGHT_HIP,
               PL.LEFT_KNEE,     PL.RIGHT_KNEE,
               PL.LEFT_ANKLE,    PL.RIGHT_ANKLE]
        ids = [i for i in ids if lm[i].visibility > 0.3]
        if len(ids) >= 4:
            ys = [w[i].y for i in ids]
            xs = [w[i].x for i in ids]
            zs = [w[i].z for i in ids]
            y_ext  = max(ys) - min(ys)
            xz_ext = math.hypot(max(xs) - min(xs), max(zs) - min(zs))
            ratio  = xz_ext / (y_ext + 1e-6)
            score_collapse = min(1.0, max(0.0, (ratio - 0.6) / 0.8))

    score = (score_orient   * 0.55 +
             score_collapse * 0.20 +
             score_velocity * 0.25)

    debug = {
        "ang": round(angle_deg, 1),
        "ori": round(score_orient,   2),
        "col": round(score_collapse, 2),
        "vel": round(score_velocity, 2),
    }
    return score, debug

# ════════════════════════════════════════════════════════
#  HUD
# ════════════════════════════════════════════════════════

def draw_hud(frame, hr: int, spo2: int, steps: int, score: float,
             state: str, alert: str, alarm: bool):
    alert_color = {
        "SOS":         (147,  20, 255),   # deep pink
        "CRITICAL":    (0,    0,  255),
        "WARNING":     (0,  140,  255),
        "CHECKING":    (0,  200,  255),
        "FALSE_ALARM": (120, 120, 120),
        "NORMAL":      (0,  220,  100),
    }.get(alert, (200, 200, 200))

    cv2.rectangle(frame, (0, 0), (FRAME_W, 58), (0, 0, 0), -1)
    cv2.rectangle(frame, (0, 0), (FRAME_W, 58), alert_color, 1)
    cv2.putText(frame, f"HR:{hr}bpm  SpO2:{spo2}%  St:{steps}",
                (6, 18), cv2.FONT_HERSHEY_SIMPLEX,
                0.42, (255, 255, 255), 1, cv2.LINE_AA)
    cv2.putText(frame, f"State:{state}  P:{score:.2f}",
                (6, 36), cv2.FONT_HERSHEY_SIMPLEX,
                0.42, (200, 200, 200), 1, cv2.LINE_AA)
    badge = f"!! {alert}" if alarm else alert
    cv2.putText(frame, badge,
                (6, 54), cv2.FONT_HERSHEY_SIMPLEX,
                0.44, alert_color, 1, cv2.LINE_AA)
    if alarm:
        cv2.rectangle(frame,
                      (0, FRAME_H - 22), (FRAME_W, FRAME_H),
                      alert_color, -1)
        if alert == "SOS":
            label = "SOS EMERGENCY"
        elif alert == "CRITICAL":
            label = "CRITICAL FALL"
        else:
            label = "FALL DETECTED"
        cv2.putText(frame, label,
                    (FRAME_W // 2 - 70, FRAME_H - 5),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.52, (255, 255, 255), 2, cv2.LINE_AA)

# ════════════════════════════════════════════════════════
#  CAMERA LOOP  (reconnect + frame-skip)
# ════════════════════════════════════════════════════════

def camera_loop():
    global output_frame, last_alert_time, last_alert_level, last_vitals_alert, cap

    fall_cnt   = 0
    stand_cnt  = 0
    fail_count = 0
    MAX_FAIL   = 30
    frame_idx  = 0

    last_score     = 0.0
    last_landmarks = None
    frame_interval = 1.0 / FPS

    while True:
        t0 = time.time()
        ret, frame = cap.read()

        if not ret:
            fail_count += 1
            time.sleep(0.05)
            if fail_count >= MAX_FAIL:
                print(f"[CAM] {fail_count} failures — reconnecting...")
                try:
                    cap.release()
                except Exception:
                    pass
                time.sleep(1.0)
                cap = open_camera()
                fail_count = 0
                if not cap.isOpened():
                    print("[CAM] Reconnect failed, retry in 3s...")
                    time.sleep(3.0)
                else:
                    print("[CAM] Reconnected OK")
            continue
        fail_count = 0

        frame = cv2.resize(frame, (FRAME_W, FRAME_H))
        frame_idx += 1
        run_pose = (frame_idx % PROCESS_EVERY_N == 0)

        if run_pose:
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            res = pose.process(rgb)
            last_score, _dbg = analyze_pose(res)
            last_landmarks = res.pose_landmarks
            # print(_dbg)   # bật khi tinh chỉnh ngưỡng góc

            if last_score > POSTURE_THRESHOLD:
                fall_cnt  += 1
                stand_cnt  = 0
            else:
                stand_cnt += 1
                fall_cnt   = max(0, fall_cnt - 1)

            vision_fall     = fall_cnt  >= FALL_FRAMES_NEEDED
            vision_standing = stand_cnt >= STAND_FRAMES_NEEDED

            prev_state = system_state
            update_fsm(vision_fall, vision_standing)
            refresh_alert()

            hr    = health["heart_rate"]
            spo2  = health["spo2"]
            steps = health["steps"]

            # Firebase event — 1 lần khi vừa confirm té
            if (system_state == State.FALL_CONFIRMED and
                    prev_state != State.FALL_CONFIRMED):
                threading.Thread(
                    target=fb_push_event,
                    args=(current_alert, hr, spo2, steps),
                    daemon=True,
                ).start()

            # ── Telegram theo ưu tiên ──
            now = time.time()
            if is_sos_active():
                pass  # SOS đã cảnh báo ở rising-edge trong _handle_sensor_data
            elif fall_status:
                elapsed_a    = now - last_alert_time
                level_change = (current_alert != last_alert_level)
                if elapsed_a > ALERT_COOLDOWN or (level_change and elapsed_a > 10.0):
                    tg_fall_alert(frame.copy(), hr, spo2, current_alert)
                    last_alert_time  = now
                    last_alert_level = current_alert
            elif _vitals_bad(hr, spo2):
                if now - last_vitals_alert > VITALS_COOLDOWN:
                    tg_vitals_alert(hr, spo2)
                    last_vitals_alert = now

        if last_landmarks is not None:
            mp_draw.draw_landmarks(
                frame, last_landmarks, mp_pose.POSE_CONNECTIONS,
                landmark_drawing_spec=LANDMARK_STYLE,
                connection_drawing_spec=CONNECTION_STYLE,
            )

        alarm = fall_status or is_sos_active()
        draw_hud(frame, health["heart_rate"], health["spo2"], health["steps"],
                 last_score, system_state.value, current_alert, alarm)

        with frame_lock:
            output_frame = frame.copy()

        if _stop_camera:
            print('[CAM] Stop flag set — exiting loop')
            break

        dt = time.time() - t0
        if dt < frame_interval:
            time.sleep(frame_interval - dt)

    try:
        cap.release()
    except Exception:
        pass
    print('[CAM] Released')

# ════════════════════════════════════════════════════════
#  PARSE HELPERS
# ════════════════════════════════════════════════════════

def _as_bool(v) -> bool:
    if isinstance(v, bool):
        return v
    if isinstance(v, (int, float)):
        return v != 0
    if isinstance(v, str):
        return v.strip().lower() in ("1", "true", "yes", "on")
    return False


def _as_num(v, default=0.0) -> float:
    try:
        return float(v)
    except (TypeError, ValueError):
        return float(default)

# ════════════════════════════════════════════════════════
#  FLASK ROUTES
# ════════════════════════════════════════════════════════

def _handle_sensor_data(data: dict):
    global _prev_sos, _sos_until

    # ── Sinh hiệu (hỗ trợ key mới heartRate + key cũ) ──
    hr_raw   = data.get("heartRate", data.get("heart_rate",
               data.get("hr", health["heart_rate"])))
    spo2_raw = data.get("spo2", health["spo2"])
    health["heart_rate"] = int(round(_as_num(hr_raw,   health["heart_rate"])))
    health["spo2"]       = int(round(_as_num(spo2_raw, health["spo2"])))

    # ── Steps ──
    health["steps"] = int(_as_num(data.get("steps", health["steps"]),
                                  health["steps"]))

    # ── fallFlag (MPU sốc) + sos ──
    health["fall_flag"] = _as_bool(data.get("fallFlag", data.get("event", False)))
    sos_now             = _as_bool(data.get("sos", False))
    health["sos"]       = sos_now

    hr    = health["heart_rate"]
    spo2  = health["spo2"]
    steps = health["steps"]

    ts = int(time.time() * 1000)
    if hr   > 0: hr_history.append(  {"t": ts, "v": hr})
    if spo2 > 0: spo2_history.append({"t": ts, "v": spo2})

    print(f"[ESP32] HR={hr} SpO2={spo2} steps={steps} "
          f"fallFlag={health['fall_flag']} sos={sos_now}")

    now = time.time()

    # ── SOS: ưu tiên cao nhất, báo ngay tại rising-edge ──
    if sos_now and not _prev_sos:
        _sos_until = now + SOS_HOLD
        print("[SOS] Nút khẩn cấp được nhấn!")
        tg_sos_alert(hr, spo2)
        threading.Thread(target=fb_push_event,
                         args=("SOS", hr, spo2, steps), daemon=True).start()
    _prev_sos = sos_now

    # ── fallFlag (gia tốc tăng nhanh) -> mở cửa sổ xác nhận bằng vision 10s ──
    if health["fall_flag"] and system_state == State.IDLE:
        print("[EVENT] MPU sốc -> PENDING (chờ vision xác nhận 10s)")
        transition(State.PENDING)

    refresh_alert()


@app.route('/data', methods=['POST'])
def receive_data():
    """ESP32 POST: {heartRate, spo2, steps, fallFlag, sos}"""
    data = request.get_json(silent=True)
    if not data:
        return jsonify(error="no JSON"), 400
    _handle_sensor_data(data)
    return jsonify(status="ok")


@app.route('/update', methods=['POST'])
def receive_update():
    """Alias /data — hỗ trợ cả JSON lẫn form-data."""
    data = request.get_json(silent=True)
    if data is None:
        data = request.form.to_dict()
    if not data:
        return jsonify(error="no data"), 400
    _handle_sensor_data(data)
    return jsonify(status="ok")


@app.route('/status')
def api_status():
    return jsonify(
        heart_rate    = health["heart_rate"],
        spo2          = health["spo2"],
        steps         = health["steps"],
        fall_flag     = health["fall_flag"],
        sos           = is_sos_active(),
        fall_detected = fall_status,
        alert         = current_alert,
        state         = system_state.value,
        timestamp     = int(time.time()),
    )


@app.route('/history')
def api_history():
    return jsonify(
        hr   = list(hr_history),
        spo2 = list(spo2_history),
    )


def _gen_frames():
    """MJPEG stream — giới hạn STREAM_FPS + MAX_CLIENTS, cleanup khi disconnect."""
    global _stream_clients

    with _stream_lock:
        if _stream_clients >= MAX_CLIENTS:
            print(f"[STREAM] Rejected — max {MAX_CLIENTS} clients reached")
            return
        _stream_clients += 1
        print(f"[STREAM] Client connected ({_stream_clients}/{MAX_CLIENTS})")

    _interval = 1.0 / STREAM_FPS
    _last     = 0.0
    encode_params = [cv2.IMWRITE_JPEG_QUALITY, JPEG_QUALITY]

    try:
        while True:
            now  = time.time()
            wait = _interval - (now - _last)
            if wait > 0:
                time.sleep(wait)
            _last = time.time()

            with frame_lock:
                frame = output_frame
            if frame is None:
                time.sleep(0.05)
                continue

            ok, buf = cv2.imencode('.jpg', frame, encode_params)
            if not ok:
                continue

            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n'
                   + buf.tobytes() + b'\r\n')

    except GeneratorExit:
        pass
    finally:
        with _stream_lock:
            _stream_clients = max(0, _stream_clients - 1)
            print(f"[STREAM] Client disconnected ({_stream_clients}/{MAX_CLIENTS})")


@app.route('/video')
def api_video():
    return Response(
        _gen_frames(),
        mimetype='multipart/x-mixed-replace; boundary=frame',
    )


@app.route('/')
def home():
    ip = os.popen("tailscale ip -4 2>/dev/null").read().strip() \
         or "localhost"
    return f"""<!DOCTYPE html>
<html><head>
  <meta charset="utf-8"><title>Fall Detection</title>
  <style>
    body{{background:#0a0e1a;color:#eee;font-family:monospace;
         text-align:center;padding:20px}}
    h1{{color:#00f5ff}}
    img{{border:2px solid #1e2d45;border-radius:8px;max-width:100%}}
    #stat{{margin:14px auto;font-size:1.05em}}
    .badge{{padding:3px 12px;border-radius:10px;font-weight:bold}}
  </style>
</head><body>
  <h1>Patient Monitoring</h1>
  <img src="/video" width="640">
  <div id="stat">Loading...</div>
  <script>
    const C={{SOS:'#ff1493',CRITICAL:'#ff2d55',WARNING:'#ff8c00',
              NORMAL:'#00ff94',CHECKING:'#00f5ff',FALSE_ALARM:'#888'}};
    setInterval(()=>fetch('/status').then(r=>r.json()).then(d=>{{
      const c=C[d.alert]||'#eee';
      document.getElementById('stat').innerHTML=
        `HR: <b>${{d.heart_rate}}</b> bpm | SpO2: <b>${{d.spo2}}</b>% |
         Steps: <b>${{d.steps}}</b> | State: <b>${{d.state}}</b> |
         Alert: <span class="badge"
           style="background:${{c}}22;color:${{c}}">${{d.alert}}</span>`;
    }}),1000);
  </script>
</body></html>"""

# ════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════

if __name__ == '__main__':
    ip = os.popen("tailscale ip -4 2>/dev/null").read().strip() or "N/A"

    init_firebase()

    _tg_send(
        f"✅ <b>Fall Detection (3D + SOS + vitals)</b> started\n"
        f"Time : {time.strftime('%Y-%m-%d %H:%M:%S')}\n"
        f"IP   : <code>{ip}</code>\n\n"
        f"API  : http://{ip}:5000/status\n"
        f"Video: http://{ip}:5000/video\n"
        f"Web  : http://{ip}:5000/"
    )

    threading.Thread(target=camera_loop,   daemon=True).start()
    threading.Thread(target=firebase_loop, daemon=True).start()
    app.run(host='0.0.0.0', port=5000, threaded=True)