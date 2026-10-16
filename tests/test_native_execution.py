"""Exercise the compiled simulator and validate finite, reproducible CSV output."""
from pathlib import Path
import csv
import math
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(arguments, directory, success=True):
    result = subprocess.run([str(ROOT / "main"), *arguments], cwd=directory,
                            capture_output=True, text=True, timeout=30)
    assert (result.returncode == 0) is success, result.stdout + result.stderr
    if not success:
        assert not list(directory.glob("*.csv")), "Invalid arguments started a simulation"
        return {}
    outputs = {}
    for kind in ("energy", "trajectory"):
        files = list(directory.glob(f"*_{kind}.csv"))
        assert len(files) == 1, files
        content = files[0].read_text()
        rows = list(csv.DictReader(content.splitlines()))
        assert len(rows) > 1, "Simulation did not progress"
        assert all(math.isfinite(float(value)) for row in rows for value in row.values())
        assert float(rows[-1]["time_s"]) > float(rows[0]["time_s"])
        outputs[kind] = content
    return outputs


def main():
    with tempfile.TemporaryDirectory(prefix="particle-native-") as name:
        root = Path(name)
        for scenario in ("hydrogen", "ep", "cyclotron", "alpha", "nbody"):
            directory = root / scenario
            directory.mkdir()
            run([scenario], directory)
        seeds = []
        for index, seed in enumerate((123, 123, 124)):
            directory = root / f"seed-{index}"
            directory.mkdir()
            seeds.append(run(["nbody", "4", f"--seed={seed}"], directory))
        assert seeds[0] == seeds[1], "Equal seeds produced different trajectories"
        assert seeds[0] != seeds[2], "Changing the seed did not change the trajectory"
        for index, arguments in enumerate((
            ["nbody", "0"], ["nbody", "513"], ["unknown"],
            ["nbody", "4", "--seed"], ["nbody", "4", "--seed=-1"],
        )):
            directory = root / f"invalid-{index}"
            directory.mkdir()
            run(arguments, directory, success=False)
    print("Five scenarios, finite outputs, deterministic seeds and invalid inputs passed.")


if __name__ == "__main__":
    main()
