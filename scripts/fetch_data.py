#!/usr/bin/env python3
"""Fetches Google Sheet tabs and saves each as a JSON file in data/."""
import csv
import io
import json
import os
import urllib.parse
import urllib.request
from datetime import datetime, timezone

SHEET_ID = "1leODqpT8inDisYiPGshWMWv2BQ_E3HpsxRzeTGu-Jjw"

TABS = {
    "city_council":     "City Council",
    "planning":         "Planning Commission",
    "supporters":       "Supporters",
    "supportive_orgs":  "Supportive Organizations",
    "opposition":       "Opposition",
    "opposition_groups":"Opposition Groups",
    "education":        "Education Contacts",
    "media":            "Media",
}


def fetch_tab(sheet_name: str) -> list[dict]:
    url = (
        f"https://docs.google.com/spreadsheets/d/{SHEET_ID}"
        f"/gviz/tq?tqx=out:csv&sheet={urllib.parse.quote(sheet_name)}"
    )
    with urllib.request.urlopen(url, timeout=30) as r:
        content = r.read().decode("utf-8")

    reader = csv.reader(io.StringIO(content))
    raw_headers = next(reader, [])

    # Assign unique names to blank/duplicate headers
    headers, seen = [], {}
    for i, h in enumerate(raw_headers):
        h = h.strip()
        key = h or f"_col{i}"
        n = seen.get(key, 0)
        seen[key] = n + 1
        headers.append(key if n == 0 else f"{key}_{n}")

    rows = []
    for row in reader:
        d = {headers[i]: v.strip() for i, v in enumerate(row) if i < len(headers)}
        if any(v for v in d.values()):
            rows.append(d)
    return rows


def main() -> None:
    os.makedirs("data", exist_ok=True)
    counts: dict[str, int] = {}

    for key, tab_name in TABS.items():
        print(f"Fetching {tab_name!r} ...", end=" ", flush=True)
        try:
            rows = fetch_tab(tab_name)
            counts[key] = len(rows)
            with open(f"data/{key}.json", "w", encoding="utf-8") as f:
                json.dump(rows, f, indent=2, ensure_ascii=False)
            print(f"{len(rows)} rows")
        except Exception as exc:
            print(f"ERROR: {exc}")
            counts[key] = 0

    # Friendly timestamp for the "Last Updated" badge
    now = datetime.now(timezone.utc)
    meta = {
        "last_updated": now.strftime("%B %-d, %Y at %-I:%M %p UTC"),
        "counts": counts,
    }
    with open("data/meta.json", "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)
    print("meta.json written — done.")


if __name__ == "__main__":
    main()
