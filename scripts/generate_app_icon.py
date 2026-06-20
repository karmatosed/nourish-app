#!/usr/bin/env python3
"""Generate Sustenance app icons from the welcome illustration."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent / "generate_app_icon.swift"


def main() -> None:
    result = subprocess.run(["swift", str(SCRIPT)], check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
