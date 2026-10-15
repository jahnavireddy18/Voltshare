"""
Train and export a demand prediction regression model for VoltNest dynamic pricing.

Usage:
  python generate_synthetic_data.py
  python train_demand_model.py
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from generate_synthetic_data import generate_dataset

FEATURE_COLUMNS = [
    "hour_of_day",
    "day_of_week",
    "charger_location_cluster",
    "charger_power_tier",
    "rolling_booking_count_last_2_hours",
]
TARGET_COLUMN = "booking_probability"

ML_DIR = Path(__file__).parent
DATA_PATH = ML_DIR / "data" / "synthetic_booking_data.csv"
MODEL_DIR = ML_DIR / "models"
FUNCTIONS_MODEL_DIR = ML_DIR.parent / "functions" / "model"


def demand_score_to_label(score: float) -> str:
    if score >= 0.66:
        return "High"
    if score >= 0.33:
        return "Medium"
    return "Low"


def demand_score_to_surge(score: float) -> float:
    return round(1.0 + float(np.clip(score, 0.0, 1.0)) * 0.8, 2)


def load_or_generate_data(data_path: Path, samples: int) -> pd.DataFrame:
    if data_path.exists():
        print(f"Loading existing dataset from {data_path}")
        return pd.read_csv(data_path)

    print(f"No dataset found — generating {samples:,} synthetic rows")
    df = generate_dataset(n_samples=samples)
    data_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(data_path, index=False)
    return df


def train_model(df: pd.DataFrame) -> tuple[Pipeline, dict]:
    x = df[FEATURE_COLUMNS].values
    y = df[TARGET_COLUMN].values

    x_train, x_test, y_train, y_test = train_test_split(
        x, y, test_size=0.2, random_state=42
    )

    pipeline = Pipeline(
        steps=[
            ("scaler", StandardScaler()),
            (
                "regressor",
                GradientBoostingRegressor(
                    n_estimators=200,
                    max_depth=5,
                    learning_rate=0.08,
                    subsample=0.85,
                    random_state=42,
                ),
            ),
        ]
    )

    pipeline.fit(x_train, y_train)
    predictions = np.clip(pipeline.predict(x_test), 0.0, 1.0)

    metrics = {
        "r2": round(float(r2_score(y_test, predictions)), 4),
        "mae": round(float(mean_absolute_error(y_test, predictions)), 4),
        "rmse": round(float(np.sqrt(mean_squared_error(y_test, predictions))), 4),
        "train_samples": len(x_train),
        "test_samples": len(x_test),
    }

    print("\nModel metrics:")
    for key, value in metrics.items():
        print(f"  {key}: {value}")

    return pipeline, metrics


def export_model(pipeline: Pipeline, metrics: dict) -> None:
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    FUNCTIONS_MODEL_DIR.mkdir(parents=True, exist_ok=True)

    model_path = MODEL_DIR / "demand_model.joblib"
    functions_model_path = FUNCTIONS_MODEL_DIR / "demand_model.joblib"

    joblib.dump(pipeline, model_path)
    joblib.dump(pipeline, functions_model_path)

    metadata = {
        "model_type": "GradientBoostingRegressor",
        "features": FEATURE_COLUMNS,
        "target": TARGET_COLUMN,
        "metrics": metrics,
        "surge_formula": "1.0 + demandScore * 0.8",
        "label_thresholds": {"high": 0.66, "medium": 0.33},
        "input_mapping": {
            "hour": "hour_of_day",
            "day": "day_of_week",
            "locationCluster": "charger_location_cluster",
            "powerTier": "charger_power_tier",
            "rollingBookings": "rolling_booking_count_last_2_hours",
        },
    }

    metadata_path = MODEL_DIR / "model_metadata.json"
    functions_metadata_path = FUNCTIONS_MODEL_DIR / "model_metadata.json"

    for path in (metadata_path, functions_metadata_path):
        path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    print(f"\nExported model -> {model_path}")
    print(f"Copied model  -> {functions_model_path}")
    print(f"Metadata      -> {metadata_path}")

    # Sanity-check predictions
    sample = np.array([[14, 1, 1, 1, 9]])
    score = float(np.clip(pipeline.predict(sample)[0], 0.0, 1.0))
    print(
        f"\nSample prediction (hub, 14:00, 9 rolling bookings): "
        f"score={score:.3f}, label={demand_score_to_label(score)}, "
        f"surge={demand_score_to_surge(score)}"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Train VoltNest demand prediction model")
    parser.add_argument("--samples", type=int, default=50_000, help="Synthetic rows if no CSV")
    parser.add_argument("--data", type=Path, default=DATA_PATH, help="Training CSV path")
    args = parser.parse_args()

    df = load_or_generate_data(args.data, args.samples)
    pipeline, metrics = train_model(df)
    export_model(pipeline, metrics)


if __name__ == "__main__":
    main()
