import json
from pathlib import Path
from typing import Dict, List, Tuple

from dotenv import load_dotenv
from benchmarking.connect import connect_to_db

JSON_PATH = Path("benchmarking/benchmark_results/run_20251209_095304.json")
ZOOMS = ("z13", "z17", "z21")
TABLE = "prototype2.trajectory_supercover_cs"


def _collect_samples(node: Dict) -> List[int]:
    samples = []
    if not isinstance(node, dict):
        return samples
    for sample in node.get("samples", []):
        traj_id = sample.get("trajectory_id")
        if traj_id is None:
            continue
        try:
            samples.append(int(traj_id))
        except (TypeError, ValueError):
            continue
    return samples


def load_ids() -> Tuple[Dict, List[int]]:
    data = json.loads(JSON_PATH.read_text())
    ids = set()
    for bench in data.get("benchmarks", []):
        result = bench.get("result", {})
        ids.update(_collect_samples(result.get("st")))
        for cst in result.get("cst_results", {}).values():
            ids.update(_collect_samples(cst))
        for area_runs in result.get("per_area_results", {}).values():
            if not isinstance(area_runs, dict):
                continue
            for run in area_runs.values():
                ids.update(_collect_samples(run))
    for traj_id in data.get("meta", {}).get("trajectory_ids", []):
        try:
            ids.add(int(traj_id))
        except (TypeError, ValueError):
            continue
    return data, sorted(ids)


def fetch_supercover(conn, zoom: str, ids: List[int]) -> Dict[int, int]:
    if not ids:
        return {}
    with conn.cursor() as cur:
        cur.execute(
            f"""
            SELECT trajectory_id, Cardinality(cellstring_{zoom})
            FROM {TABLE}
            WHERE trajectory_id = ANY(%s)
            """,
            (ids,),
        )
        return {int(traj_id): int(count) for traj_id, count in cur.fetchall() if count is not None}


def embed(data: Dict, lookup_per_zoom: Dict[str, Dict[int, int]]) -> None:
    meta = data.setdefault("meta", {})
    dest = meta.setdefault("trajectory_supercover_cardinalities", {})
    for zoom, values in lookup_per_zoom.items():
        dest[zoom] = {str(traj_id): count for traj_id, count in sorted(values.items())}


if __name__ == "__main__":
    load_dotenv()
    data, ids = load_ids()
    if not ids:
        raise SystemExit("No trajectory IDs found in the report.")
    conn = connect_to_db()
    try:
        per_zoom = {zoom: fetch_supercover(conn, zoom, ids) for zoom in ZOOMS}
    finally:
        conn.close()
    embed(data, per_zoom)
    JSON_PATH.write_text(json.dumps(data, indent=2))
    print(f"Updated {JSON_PATH} with supercover cardinalities for {len(ids)} trajectories.")
