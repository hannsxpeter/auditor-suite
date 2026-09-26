---
type: regex
target:
  source: file
  path: uxaudit.md
pattern: '(NavBar\.jsx(:| line | \(line |, line |#L)2[0-9]|SignIn\.jsx(:| line | \(line |, line |#L)(29|3[01]|5[0-3]))\b'
---

Finds "Log in" in the header against "Sign in" on the sign-in page at src/components/NavBar.jsx:26 (CNT-R3).
