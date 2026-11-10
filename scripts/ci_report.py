#!/usr/bin/env python3
"""CI reporting without third-party actions.

  ci_report.py tests <xunit.xml>...           annotate failed tests on the PR + write a summary
  ci_report.py coverage <codecov.json> --min N   summarize TVKit line coverage, fail below N%
"""
import json
import os
import sys
import xml.etree.ElementTree as ET

SUMMARY = os.environ.get("GITHUB_STEP_SUMMARY")


def summary(md):
    if SUMMARY:
        with open(SUMMARY, "a") as f:
            f.write(md + "\n")
    else:
        print(md)


def esc(s):  # GitHub workflow-command escaping
    return s.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def tests(paths):
    total = failed = skipped = 0
    failures = []
    for path in paths:
        if not os.path.exists(path):
            continue
        for case in ET.parse(path).iter("testcase"):
            total += 1
            name = f"{case.get('classname', '')}.{case.get('name', '')}".strip(".")
            if case.find("skipped") is not None:
                skipped += 1
            for f in list(case.findall("failure")) + list(case.findall("error")):
                failed += 1
                msg = (f.get("message") or f.text or "failed").strip()
                failures.append((name, msg))
                print(f"::error title=Test failed: {esc(name)}::{esc(msg)}")
    if total == 0:
        print("::error title=No test results::No test cases found in the xUnit report")
        return 1
    icon = "❌" if failed else "✅"
    summary(f"## {icon} Tests\n\n| Passed | Failed | Skipped | Total |\n|---|---|---|---|\n"
            f"| {total - failed - skipped} | {failed} | {skipped} | {total} |\n")
    if failures:
        summary("| Failed test | Message |\n|---|---|\n" +
                "\n".join(f"| `{n}` | {m.splitlines()[0][:200]} |" for n, m in failures))
    return 1 if failed else 0


def coverage(path, minimum):
    data = json.load(open(path))["data"][0]["files"]
    rows, covered, count = [], 0, 0
    for f in data:
        name = f["filename"]
        if "/Sources/TVKit/" not in name:
            continue  # gate the core library; the SwiftUI app layer isn't unit-tested
        lines = f["summary"]["lines"]
        covered += lines["covered"]
        count += lines["count"]
        rows.append((lines["percent"], name.split("/Sources/")[1]))
    pct = 100.0 * covered / count if count else 0.0
    ok = pct >= minimum
    summary(f"## {'✅' if ok else '❌'} TVKit coverage: {pct:.1f}% (minimum {minimum:g}%)\n\n"
            "<details><summary>Per file</summary>\n\n| Lines | File |\n|---|---|\n" +
            "\n".join(f"| {p:.1f}% | `{n}` |" for p, n in sorted(rows)) + "\n\n</details>\n")
    if not ok:
        print(f"::error title=Coverage below minimum::TVKit line coverage {pct:.1f}% is below {minimum:g}%")
        return 1
    print(f"TVKit line coverage {pct:.1f}% (minimum {minimum:g}%)")
    return 0


if __name__ == "__main__":
    cmd, args = sys.argv[1], sys.argv[2:]
    if cmd == "tests":
        sys.exit(tests(args))
    if cmd == "coverage":
        sys.exit(coverage(args[0], float(args[args.index("--min") + 1])))
    sys.exit(f"unknown command {cmd}")
