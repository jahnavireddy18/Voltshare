"""
Generate synthetic historical EV charging booking data for demand model training.

Features mirror production inputs:
  - hour_of_day
  - day_of_week (0=Monday … 6=Sunday)
  - charger_location_cluster
  - charger_power_tier
  - rolling_booking_count_last_2_hours
  - booking_probability (target, 0–1)
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

RANDOM_SEED = 42
NUM_CLUSTERS = 5
NUM_POWER_TIERS = 3
MAX_ROLLING_BOOKINGS = 25

# Cluster demand affinity (urban hubs vs residential)
CLUSTER_BASE = np.array([0.05, 0.20, 0.15, 0.18, 0.08])

# Fast-charger tier attracts more demand
TIER_BOOST = np.array([0.0, 0.10, 0.18])


def _hour_effect(hour: np.ndarray) -> np.ndarray:
    """Morning/evening peaks and midday lunch bump."""
    effect = np.zeros_like(hour, dtype=float)
    effect += np.where((hour >= 7) & (hour <= 9), 0.22, 0.0)
    effect += np.where((hour >= 17) & (hour <= 20), 0.28, 0.0)
    effect += np.where((hour >= 12) & (hour <= 14), 0.10, 0.0)
    effect += np.where((hour <= 5) | (hour >= 23), -0.12, 0.0)
    return effect


def _day_effect(day: np.ndarray, hour: np.ndarray) -> np.ndarray:
    """Weekend uplift with midday activity."""
    effect = np.zeros_like(day, dtype=float)
    weekend = day >= 5
    effect += np.where(weekend, 0.08, 0.0)
    effect += np.where(weekend & (hour >= 10) & (hour <= 16), 0.12, 0.0)
    return effect


def compute_booking_probability(
    hour: np.ndarray,
    day: np.ndarray,
    cluster: np.ndarray,
    tier: np.ndarray,
    rolling: np.ndarray,
    noise_scale: float = 0.06,
    rng: np.random.Generator | None = None,
) -> np.ndarray:
    """Ground-truth demand signal with realistic noise."""
    if rng is None:
        rng = np.random.default_rng(RANDOM_SEED)

    base = 0.18
    score = (
        base
        + _hour_effect(hour)
        + _day_effect(day, hour)
        + CLUSTER_BASE[cluster]
        + TIER_BOOST[tier]
        + np.clip(rolling / 20.0, 0.0, 1.0) * 0.35
        + rng.normal(0, noise_scale, size=hour.shape)
    )
    return np.clip(score, 0.0, 1.0)


def generate_dataset(n_samples: int = 50_000, seed: int = RANDOM_SEED) -> pd.DataFrame:
    rng = np.random.default_rng(seed)

    hour = rng.integers(0, 24, size=n_samples)
    day = rng.integers(0, 7, size=n_samples)
    cluster = rng.integers(0, NUM_CLUSTERS, size=n_samples)
    tier = rng.integers(0, NUM_POWER_TIERS, size=n_samples)
    rolling = rng.integers(0, MAX_ROLLING_BOOKINGS + 1, size=n_samples)

    # Correlate rolling bookings with time-of-day peaks
    peak_mask = ((hour >= 7) & (hour <= 9)) | ((hour >= 17) & (hour <= 20))
    rolling = np.where(
        peak_mask,
        np.minimum(rolling + rng.integers(2, 8, size=n_samples), MAX_ROLLING_BOOKINGS),
        rolling,
    )

    probability = compute_booking_probability(hour, day, cluster, tier, rolling, rng=rng)

    return pd.DataFrame(
        {
            "hour_of_day": hour,
            "day_of_week": day,
            "charger_location_cluster": cluster,
            "charger_power_tier": tier,
            "rolling_booking_count_last_2_hours": rolling,
            "booking_probability": probability,
        }
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate synthetic booking demand data")
    parser.add_argument("--samples", type=int, default=50_000, help="Number of rows")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).parent / "data" / "synthetic_booking_data.csv",
        help="Output CSV path",
    )
    args = parser.parse_args()

    df = generate_dataset(n_samples=args.samples)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(args.output, index=False)

    print(f"Generated {len(df):,} rows -> {args.output}")
    print(df.describe().round(3).to_string())
    print(f"\nTarget mean: {df['booking_probability'].mean():.3f}")


if __name__ == "__main__":
    main()
