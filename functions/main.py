"""
VoltNest demand prediction Cloud Function.

POST /predictDemand
Body: { hour, day, locationCluster, powerTier, rollingBookings }
Response: { demandScore, surgeMultiplier, demandLabel }
"""

from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path

import joblib
import numpy as np
from firebase_admin import initialize_app, messaging, firestore
from firebase_functions import https_fn, firestore_fn, options

initialize_app()

MODEL_PATH = Path(__file__).parent / "model" / "demand_model.joblib"
FEATURE_ORDER = [
    "hour_of_day",
    "day_of_week",
    "charger_location_cluster",
    "charger_power_tier",
    "rolling_booking_count_last_2_hours",
]

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}


@lru_cache(maxsize=1)
def _load_model():
    if not MODEL_PATH.exists():
        raise FileNotFoundError(f"Model not found at {MODEL_PATH}")
    return joblib.load(MODEL_PATH)


def _demand_score_to_label(score: float) -> str:
    if score >= 0.66:
        return "High"
    if score >= 0.33:
        return "Medium"
    return "Low"


def _demand_score_to_surge(score: float) -> float:
    return round(1.0 + float(np.clip(score, 0.0, 1.0)) * 0.8, 2)


def _validate_input(body: dict) -> tuple[list[float] | None, str | None]:
    required = {
        "hour": (0, 23),
        "day": (0, 6),
        "locationCluster": (0, 4),
        "powerTier": (0, 2),
        "rollingBookings": (0, 50),
    }

    features: list[float] = []
    for key, (lo, hi) in required.items():
        if key not in body:
            return None, f"Missing required field: {key}"
        try:
            value = int(body[key])
        except (TypeError, ValueError):
            return None, f"Invalid value for {key}: must be an integer"

        if value < lo or value > hi:
            return None, f"{key} must be between {lo} and {hi}"

        features.append(float(value))

    return features, None


def _predict(features: list[float]) -> dict:
    model = _load_model()
    vector = np.array([features])
    demand_score = float(np.clip(model.predict(vector)[0], 0.0, 1.0))

    return {
        "demandScore": round(demand_score, 4),
        "surgeMultiplier": _demand_score_to_surge(demand_score),
        "demandLabel": _demand_score_to_label(demand_score),
        "source": "ml",
    }


def _json_response(payload: dict, status: int = 200) -> https_fn.Response:
    return https_fn.Response(
        json.dumps(payload),
        status=status,
        headers={**CORS_HEADERS, "Content-Type": "application/json"},
    )


@https_fn.on_request(
    region="asia-south1",
    cors=options.CorsOptions(cors_origins="*", cors_methods=["POST", "OPTIONS"]),
)
def predictDemand(req: https_fn.Request) -> https_fn.Response:
    """ML-powered demand score and surge multiplier for dynamic pricing."""
    if req.method == "OPTIONS":
        return https_fn.Response("", status=204, headers=CORS_HEADERS)

    if req.method != "POST":
        return _json_response({"error": "Method not allowed. Use POST."}, status=405)

    try:
        body = req.get_json(silent=True)
        if not body:
            return _json_response({"error": "Request body must be valid JSON"}, status=400)

        features, error = _validate_input(body)
        if error:
            return _json_response({"error": error}, status=400)

        result = _predict(features)
        return _json_response(result)

    except FileNotFoundError as exc:
        return _json_response({"error": str(exc)}, status=503)
    except Exception as exc:
        return _json_response({"error": f"Prediction failed: {exc}"}, status=500)

@firestore_fn.on_document_created(document="bookings/{bookingId}", region="asia-south1")
def on_booking_created(event: firestore_fn.Event[firestore_fn.DocumentSnapshot | None]) -> None:
    """Triggered when a booking is created."""
    if event.data is None:
        return
    booking_data = event.data.to_dict()
    
    driver_id = booking_data.get("userId")
    if driver_id:
        _send_notification(
            driver_id, 
            "Booking Confirmed", 
            f"Your booking at {booking_data.get('chargerName', 'VoltNest Charger')} is confirmed.", 
            {"action": "view_booking"}
        )
        
    host_id = booking_data.get("hostId")
    if host_id:
        _send_notification(
            host_id, 
            "New Booking Received", 
            f"A new booking was made for your charger {booking_data.get('chargerName', '')}.", 
            {"action": "open_dashboard"}
        )

@firestore_fn.on_document_updated(document="bookings/{bookingId}", region="asia-south1")
def on_booking_updated(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot | None]]) -> None:
    """Triggered when a booking status changes."""
    if event.data is None or event.data.before is None or event.data.after is None:
        return
    
    before_data = event.data.before.to_dict()
    after_data = event.data.after.to_dict()
    
    old_status = before_data.get("status")
    new_status = after_data.get("status")
    
    if old_status != new_status:
        driver_id = after_data.get("userId")
        host_id = after_data.get("hostId")
        charger_name = after_data.get("chargerName", "VoltNest Charger")
        
        if new_status == "active":
            if driver_id:
                _send_notification(driver_id, "Session Started", f"Your charging session at {charger_name} has started.", {"action": "open_session"})
            if host_id:
                _send_notification(host_id, "Session Started", f"A driver started charging at {charger_name}.", {"action": "open_dashboard"})
        elif new_status == "completed":
            if driver_id:
                _send_notification(driver_id, "Session Completed", f"Your charging session at {charger_name} is complete.", {"action": "view_booking"})
            if host_id:
                _send_notification(host_id, "Session Completed", f"A charging session at {charger_name} has finished.", {"action": "open_dashboard"})

def _send_notification(user_id: str, title: str, body: str, data: dict) -> None:
    db = firestore.client()
    user_doc = db.collection("users").document(user_id).get()
    
    if user_doc.exists:
        tokens = user_doc.to_dict().get("fcmTokens", [])
        if tokens:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(title=title, body=body),
                data=data,
                tokens=tokens,
            )
            try:
                messaging.send_each_for_multicast(message)
            except Exception as e:
                print(f"Error sending message: {e}")

