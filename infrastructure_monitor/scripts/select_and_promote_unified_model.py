import argparse
import glob
import json
import os
import shutil
from typing import Dict, List, Tuple

import pandas as pd
from ultralytics import YOLO


DEFAULT_EXPECTED_CLASSES = ["pothole", "road_crack", "bridge_crack", "pipeline_leak"]
METRIC_COLUMN = "metrics/mAP50-95(B)"


def normalize_name(name: str) -> str:
    return name.strip().lower().replace(" ", "_")


def read_best_metric(results_csv: str, metric_column: str = METRIC_COLUMN) -> Tuple[float, int]:
    df = pd.read_csv(results_csv)
    if metric_column not in df.columns:
        raise ValueError(f"Missing column '{metric_column}' in {results_csv}")

    idx = int(df[metric_column].idxmax())
    best_val = float(df.loc[idx, metric_column])
    return best_val, idx + 1


def extract_classes(model_path: str) -> List[str]:
    model = YOLO(model_path)
    names = model.names
    if isinstance(names, dict):
        return [str(names[k]) for k in sorted(names.keys())]
    return [str(v) for v in names]


def discover_candidates(runs_detect_dir: str) -> List[Dict[str, object]]:
    candidates: List[Dict[str, object]] = []

    for run_dir in sorted(glob.glob(os.path.join(runs_detect_dir, "*"))):
        results_csv = os.path.join(run_dir, "results.csv")
        best_pt = os.path.join(run_dir, "weights", "best.pt")
        if not (os.path.isfile(results_csv) and os.path.isfile(best_pt)):
            continue

        best_metric, best_epoch = read_best_metric(results_csv)
        class_names = extract_classes(best_pt)

        candidates.append(
            {
                "run_name": os.path.basename(run_dir),
                "run_dir": run_dir,
                "best_pt": best_pt,
                "best_metric": best_metric,
                "best_epoch": best_epoch,
                "class_names": class_names,
            }
        )

    candidates.sort(key=lambda x: float(x["best_metric"]), reverse=True)
    return candidates


def choose_candidate(candidates: List[Dict[str, object]], run_name: str = "") -> Dict[str, object]:
    if not candidates:
        raise RuntimeError("No valid runs found under runs/detect with both results.csv and weights/best.pt")

    if run_name:
        for c in candidates:
            if c["run_name"] == run_name:
                return c
        raise RuntimeError(f"Run '{run_name}' not found under runs/detect")

    return candidates[0]


def validate_expected_classes(class_names: List[str], expected_classes: List[str]) -> Tuple[List[str], List[str]]:
    actual_normalized = {normalize_name(x) for x in class_names}
    expected_normalized = [normalize_name(x) for x in expected_classes]

    present = [x for x in expected_normalized if x in actual_normalized]
    missing = [x for x in expected_normalized if x not in actual_normalized]
    return present, missing


def promote_model(best_pt: str, target_model_path: str) -> None:
    os.makedirs(os.path.dirname(target_model_path), exist_ok=True)
    shutil.copy2(best_pt, target_model_path)


def write_metadata(meta_path: str, payload: Dict[str, object]) -> None:
    os.makedirs(os.path.dirname(meta_path), exist_ok=True)
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Select and promote a unified YOLO detect model")
    parser.add_argument("--runs-dir", default="runs/detect", help="Path to detect runs directory")
    parser.add_argument("--target", default="models/final_model.pt", help="Target path for promoted model")
    parser.add_argument("--metadata", default="models/final_model_meta.json", help="Metadata JSON output path")
    parser.add_argument("--run-name", default="", help="Optional explicit run name under runs/detect")
    parser.add_argument(
        "--expected-classes",
        nargs="+",
        default=DEFAULT_EXPECTED_CLASSES,
        help="Expected class names that unified model should support",
    )
    parser.add_argument(
        "--allow-partial",
        action="store_true",
        help="Promote model even if some expected classes are missing",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    candidates = discover_candidates(args.runs_dir)
    print("Detected candidates (sorted by best mAP50-95):")
    for c in candidates:
        print(
            f"- {c['run_name']}: best_mAP50-95={c['best_metric']:.4f}, "
            f"epoch={c['best_epoch']}, classes={c['class_names']}"
        )

    selected = choose_candidate(candidates, run_name=args.run_name)
    present, missing = validate_expected_classes(selected["class_names"], args.expected_classes)

    print("\nSelected run:")
    print(
        f"- {selected['run_name']} from {selected['best_pt']} "
        f"(best_mAP50-95={selected['best_metric']:.4f}, epoch={selected['best_epoch']})"
    )
    print(f"- Present expected classes: {present}")
    print(f"- Missing expected classes: {missing}")

    if missing and not args.allow_partial:
        raise RuntimeError(
            "Selected model does not cover all expected classes. "
            "Use --run-name to choose another run, retrain a multi-class detect model, "
            "or pass --allow-partial to promote anyway."
        )

    promote_model(selected["best_pt"], args.target)
    metadata = {
        "source_run": selected["run_name"],
        "source_weights": selected["best_pt"],
        "best_metric_map50_95": selected["best_metric"],
        "best_epoch": selected["best_epoch"],
        "class_names": selected["class_names"],
        "expected_classes": args.expected_classes,
        "present_expected_classes": present,
        "missing_expected_classes": missing,
        "target_model": args.target,
    }
    write_metadata(args.metadata, metadata)

    print("\nPromotion complete:")
    print(f"- Model: {args.target}")
    print(f"- Metadata: {args.metadata}")


if __name__ == "__main__":
    main()
