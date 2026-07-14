#!/usr/bin/env python3
"""Fail if any tracked text file contains a non-ASCII character.

The repo is plain ASCII by policy: no em dashes, en dashes, smart quotes, or
emoji (see CONTRIBUTING.md). Enforcing ASCII is a simple superset of that rule.
This scans only git-tracked files and skips anything that is not UTF-8 text.
"""
import subprocess
import sys


def main() -> int:
    files = subprocess.check_output(["git", "ls-files"], text=True).splitlines()
    bad = []
    for path in files:
        if not path:
            continue
        try:
            with open(path, encoding="utf-8") as handle:
                for number, line in enumerate(handle, 1):
                    for column, char in enumerate(line, 1):
                        if ord(char) > 127:
                            bad.append(
                                "{}:{}:{}: non-ASCII U+{:04X}".format(
                                    path, number, column, ord(char)
                                )
                            )
                            break
        except (UnicodeDecodeError, IsADirectoryError, FileNotFoundError):
            continue
    if bad:
        print("\n".join(bad))
        print(
            "Found non-ASCII characters. The repo is plain ASCII: no em dashes, "
            "en dashes, smart quotes, or emoji (see CONTRIBUTING.md)."
        )
        return 1
    print("clean: all tracked text files are ASCII")
    return 0


if __name__ == "__main__":
    sys.exit(main())
