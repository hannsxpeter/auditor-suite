# _parse.awk: parse an auditor-suite report into tab-separated records.
#
# Canonical copy: shared/scripts/_parse.awk in the auditor-suite hub. Used by
# score.sh and check-report.sh so both read a report the same way. POSIX awk
# (tested with BSD awk and mawk); no gawk extensions.
#
# Records (tab-separated, first field is the record type):
#   H2    line  heading                  a "## " section heading
#   PH    line  text                     a placeholder ({{ or @@) left outside code
#   META  key   value                    mode, active, na, notassessed, verdict, calibration
#   F     id    line  title              a finding heading "### [ID] title"
#   FS    id    severity confidence effort dimension
#   FF    id    key   value              one field (location, evidence, impact, ...)
#   FL    id    path  start  end  token  one location from the Location field
#   FE    id    span                     one inline code span from Evidence
#   FX    line  text                     a malformed line inside Findings
#   SYS   id    members  line            a systemic pattern and its member IDs
#   NH    dim   line                     a dimension-notes heading
#   N     dim   cards  line              the Checked: cards of a dimension
#   ST    count none                     strengths: cited locations, "None found."
#   G     name  begin|end  line          a generated-block marker

function trim(s) {
  sub(/^[ \t]+/, "", s)
  sub(/[ \t]+$/, "", s)
  return s
}

# Remove inline code spans so text inside backticks is ignored.
function strip_code(s,    out, a, b, rest) {
  out = ""
  rest = s
  while ((a = index(rest, "`")) > 0) {
    out = out substr(rest, 1, a - 1)
    rest = substr(rest, a + 1)
    b = index(rest, "`")
    if (b == 0) { rest = ""; break }
    rest = substr(rest, b + 1)
  }
  return out rest
}

# Split inline code spans of s into arr; returns the count.
function code_spans(s, arr,    n, a, b, rest) {
  n = 0
  rest = s
  while ((a = index(rest, "`")) > 0) {
    rest = substr(rest, a + 1)
    b = index(rest, "`")
    if (b == 0) break
    n++
    arr[n] = substr(rest, 1, b - 1)
    rest = substr(rest, b + 1)
  }
  return n
}

# Finding IDs (ABC-123) in s, comma-joined.
function finding_ids(s,    out, rest, t) {
  out = ""
  rest = s
  while (match(rest, /[A-Z][A-Z0-9]*-[0-9][0-9][0-9]/)) {
    t = substr(rest, RSTART, RLENGTH)
    out = out (out == "" ? "" : ",") t
    rest = substr(rest, RSTART + RLENGTH)
  }
  return out
}

# Card IDs (ABC-R1) in s, comma-joined.
function card_ids(s,    out, rest, t) {
  out = ""
  rest = s
  while (match(rest, /[A-Z][A-Z0-9]*-R[0-9]+/)) {
    t = substr(rest, RSTART, RLENGTH)
    out = out (out == "" ? "" : ",") t
    rest = substr(rest, RSTART + RLENGTH)
  }
  return out
}

function cap_word(s) {
  s = tolower(trim(s))
  return toupper(substr(s, 1, 1)) substr(s, 2)
}

function flush_finding(    k, n, i, sp, tok, path, lines, dash, start, end_) {
  if (fid == "") return
  printf "FS\t%s\t%s\t%s\t%s\t%s\n", fid, fsev, fconf, feff, fdim
  for (k in field) {
    printf "FF\t%s\t%s\t%s\n", fid, k, field[k]
  }
  if ("location" in field) {
    n = code_spans(field["location"], sp)
    for (i = 1; i <= n; i++) {
      tok = trim(sp[i])
      if (match(tok, /:[0-9]+(-[0-9]+)?$/)) {
        path = substr(tok, 1, RSTART - 1)
        lines = substr(tok, RSTART + 1)
        dash = index(lines, "-")
        if (dash > 0) {
          start = substr(lines, 1, dash - 1)
          end_ = substr(lines, dash + 1)
        } else {
          start = lines
          end_ = lines
        }
        if (path != "") printf "FL\t%s\t%s\t%s\t%s\t%s\n", fid, path, start, end_, tok
      }
    }
  }
  if ("evidence" in field) {
    n = code_spans(field["evidence"], sp)
    for (i = 1; i <= n; i++) printf "FE\t%s\t%s\n", fid, sp[i]
  }
  split("", field)
  fid = ""; fsev = ""; fconf = ""; feff = ""; fdim = ""; lastkey = ""
}

BEGIN {
  section = ""
  fid = ""
  strengths = 0
  strengths_none = 0
}

{
  sub(/\r$/, "")
  line = $0
}

# Placeholders anywhere outside code spans and HTML comments.
{
  plain = strip_code(line)
  if (plain !~ /^[ \t]*<!--/ && (index(plain, "{{") > 0 || index(plain, "@@") > 0)) {
    printf "PH\t%d\t%s\n", NR, substr(trim(line), 1, 100)
  }
}

# Generated-block markers.
/^<!-- BEGIN GENERATED: / {
  name = line
  sub(/^<!-- BEGIN GENERATED: /, "", name)
  sub(/[ (].*$/, "", name)
  printf "G\t%s\tbegin\t%d\n", name, NR
  next
}
/^<!-- END GENERATED: / {
  name = line
  sub(/^<!-- END GENERATED: /, "", name)
  sub(/[ (].*$/, "", name)
  printf "G\t%s\tend\t%d\n", name, NR
  next
}

# Section headings.
/^## / {
  flush_finding()
  section = trim(substr(line, 4))
  printf "H2\t%d\t%s\n", NR, section
  next
}

# Banner metadata.
/Mode: / && section == "" {
  m = line
  sub(/^.*Mode: /, "", m)
  sub(/ .*$/, "", m)
  sub(/[.;,]+$/, "", m)
  printf "META\tmode\t%s\n", m
}

section == "Snapshot" && /^- Active dimensions:/ {
  v = line; sub(/^- Active dimensions:/, "", v); printf "META\tactive\t%s\n", trim(v); next
}
section == "Snapshot" && /^- Not applicable:/ {
  v = line; sub(/^- Not applicable:/, "", v); printf "META\tna\t%s\n", trim(v); next
}
section == "Snapshot" && /^- Not assessed:/ {
  v = line; sub(/^- Not assessed:/, "", v); printf "META\tnotassessed\t%s\n", trim(v); next
}
section == "Overall score" && /^Verdict:/ {
  v = line; sub(/^Verdict:/, "", v); printf "META\tverdict\t%s\n", trim(v); next
}
section == "Overall score" && /^Calibration:/ {
  v = line; sub(/^Calibration:/, "", v); printf "META\tcalibration\t%s\n", trim(v); next
}

section == "Strengths (preserve these)" {
  n = code_spans(line, sp)
  for (i = 1; i <= n; i++) if (sp[i] ~ /:[0-9]+(-[0-9]+)?$/) strengths++
  if (line ~ /None found/) strengths_none = 1
  next
}

section == "Systemic patterns (root causes)" && /^- SYS-[0-9]+/ {
  sid = line
  sub(/^- /, "", sid)
  sub(/[^A-Z0-9-].*$/, "", sid)
  rest = line
  sub(/^- SYS-[0-9]+/, "", rest)
  printf "SYS\t%s\t%s\t%d\n", sid, finding_ids(rest), NR
  next
}

section == "Findings" {
  if (line ~ /^### /) {
    flush_finding()
    if (match(line, /^### \[[A-Z][A-Z0-9]*-[0-9][0-9][0-9]\] /)) {
      fid = substr(line, 6, RLENGTH - 7)
      title = trim(substr(line, RLENGTH + 1))
      printf "F\t%s\t%d\t%s\n", fid, NR, title
    } else {
      printf "FX\t%d\t%s\n", NR, "finding heading is not \"### [ID-123] Title\": " substr(line, 1, 80)
    }
    next
  }
  if (fid == "") {
    if (trim(line) != "" && line !~ /^<!--/) printf "FX\t%d\t%s\n", NR, "text outside a finding block: " substr(trim(line), 1, 80)
    next
  }
  if (line ~ /^- [A-Za-z][A-Za-z ]*:/) {
    key = line
    sub(/^- /, "", key)
    val = substr(key, index(key, ":") + 1)
    key = tolower(trim(substr(key, 1, index(key, ":") - 1)))
    if (key == "severity") {
      np = split(line, parts, "|")
      for (i = 1; i <= np; i++) {
        kv = parts[i]
        sub(/^- /, "", kv)
        c = index(kv, ":")
        if (c == 0) continue
        k2 = tolower(trim(substr(kv, 1, c - 1)))
        v2 = trim(substr(kv, c + 1))
        if (k2 == "severity") fsev = cap_word(v2)
        else if (k2 == "confidence") fconf = cap_word(v2)
        else if (k2 == "effort") feff = toupper(trim(v2))
        else if (k2 == "dimension") fdim = trim(v2)
      }
      lastkey = ""
    } else {
      field[key] = trim(val)
      lastkey = key
    }
    next
  }
  if (line ~ /^```/) {
    printf "FX\t%d\t%s\n", NR, "fenced code block inside a finding; quote code inline with single backticks instead"
    next
  }
  if (trim(line) != "" && lastkey != "") {
    field[lastkey] = field[lastkey] " " trim(line)
    next
  }
  next
}

section == "Dimension notes" && /^### / {
  d = trim(substr(line, 5))
  sub(/[: ].*$/, "", d)
  ndim = d
  printf "NH\t%s\t%d\n", d, NR
  next
}
section == "Dimension notes" && /^- Checked:/ {
  v = line
  sub(/^- Checked:/, "", v)
  cards = card_ids(v)
  if (index(v, "{{") > 0) cards = "PLACEHOLDER"
  else if (cards == "" && v ~ /none/) cards = "none"
  printf "N\t%s\t%s\t%d\n", ndim, cards, NR
  next
}

END {
  flush_finding()
  printf "ST\t%d\t%d\n", strengths, strengths_none
}
