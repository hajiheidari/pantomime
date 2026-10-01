#!/usr/bin/env python3
"""Sets the real package / bundle id everywhere in one go.

    python3 tool/set_package.py com.yourname.pantomime

Updates Android namespace + applicationId, MainActivity's Kotlin package and
folder, and the iOS bundle identifiers (Runner + RunnerTests).
"""
import pathlib
import re
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


def main() -> None:
    if len(sys.argv) != 2 or not re.fullmatch(r"[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2,}", sys.argv[1]):
        sys.exit("usage: tool/set_package.py com.yourname.pantomime  (lowercase, 3+ parts)")
    new = sys.argv[1]

    gradle = ROOT / "android/app/build.gradle.kts"
    text = gradle.read_text()
    old = re.search(r'applicationId = "([^"]+)"', text).group(1)
    gradle.write_text(text.replace(f'"{old}"', f'"{new}"'))

    kotlin_root = ROOT / "android/app/src/main/kotlin"
    src = kotlin_root.joinpath(*old.split(".")) / "MainActivity.kt"
    dst_dir = kotlin_root.joinpath(*new.split("."))
    dst_dir.mkdir(parents=True, exist_ok=True)
    activity = src.read_text().replace(f"package {old}", f"package {new}")
    (dst_dir / "MainActivity.kt").write_text(activity)
    if src.parent != dst_dir:
        src.unlink()
        # Remove now-empty old folders.
        d = src.parent
        while d != kotlin_root and not any(d.iterdir()):
            d.rmdir()
            d = d.parent

    pbx = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
    p = pbx.read_text()
    p = re.sub(r"PRODUCT_BUNDLE_IDENTIFIER = [^;]*\.RunnerTests;", f"PRODUCT_BUNDLE_IDENTIFIER = {new}.RunnerTests;", p)
    p = re.sub(r"PRODUCT_BUNDLE_IDENTIFIER = (?![^;]*RunnerTests)[^;]*;", f"PRODUCT_BUNDLE_IDENTIFIER = {new};", p)
    pbx.write_text(p)
    print(f"package: {old} → {new}")


if __name__ == "__main__":
    main()
