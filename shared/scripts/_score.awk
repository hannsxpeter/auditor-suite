# _score.awk: compute scores and the generated report blocks.
#
# Canonical copy: shared/scripts/_score.awk in the auditor-suite hub.
# Input 1: assets/dimensions.tsv rows (id, weight, applies, floor, name).
# Input 2: records from _parse.awk.
# Variables: headline, quick_headline, report_file.
# Output: blocks, each introduced by a line "#BLOCK <name>":
#   score, fix-first, plan, chat, and "problems" (lines scoring could not use).
#
# The rules implemented here are documented in references/protocol.md
# (section "Scoring"); change both together. POSIX awk only.

function grade(s) {
  if (s >= 90) return "A"
  if (s >= 80) return "B"
  if (s >= 70) return "C"
  if (s >= 60) return "D"
  return "F"
}
function glabel(g) {
  if (g == "A") return "exemplary"
  if (g == "B") return "solid, minor issues"
  if (g == "C") return "adequate, real gaps"
  if (g == "D") return "weak, systemic problems"
  return "failing, critical deficiencies"
}
function sevrank(s) {
  if (s == "Critical") return 0
  if (s == "High") return 1
  if (s == "Medium") return 2
  if (s == "Low") return 3
  return 4
}
function effrank(e) {
  if (e == "S") return 0
  if (e == "M") return 1
  if (e == "L") return 2
  return 3
}
function points(s) {
  if (s == "Critical") return 25
  if (s == "High") return 10
  if (s == "Medium") return 3
  if (s == "Low") return 1
  return 0
}
function first_sentence(s,    p) {
  p = index(s, ". ")
  if (p > 0) s = substr(s, 1, p)
  if (length(s) > 150) s = substr(s, 1, 147) "..."
  return s
}
# Sort arr[1..n] of "key<TAB>payload" strings by key, in place (insertion sort).
function isort(arr, n,    i, j, t) {
  for (i = 2; i <= n; i++) {
    t = arr[i]
    j = i - 1
    while (j > 0 && arr[j] > t) { arr[j + 1] = arr[j]; j-- }
    arr[j + 1] = t
  }
}
function payload(s) { return substr(s, index(s, "\t") + 1) }
function join_ids(arr, n,    i, out) {
  out = ""
  for (i = 1; i <= n; i++) out = out (i > 1 ? ", " : "") payload(arr[i])
  return (out == "" ? "none" : out)
}

BEGIN { FS = "\t" }

FNR == NR {
  if ($0 ~ /^[ \t]*#/ || $0 ~ /^[ \t]*$/) next
  nd++
  dims[nd] = $1
  weight[$1] = $2 + 0
  floor_[$1] = $4
  dname[$1] = $5
  isdim[$1] = 1
  next
}
$1 == "META" { meta[$2] = $3; next }
$1 == "F"    { nf++; fid[nf] = $2; title[$2] = $4; next }
$1 == "FS"   { sev[$2] = $3; conf[$2] = $4; eff[$2] = $5; next }
$1 == "FF"   { if ($3 == "impact") impact[$2] = $4; if ($3 == "related") related[$2] = $4; next }

END {
  mode = meta["mode"]
  quick = (mode == "quick")
  partial = (mode ~ /^only=/)
  np = 0

  # Active dimensions, in table order.
  na_ = split(meta["active"], toks, /[ ,]+/)
  for (i = 1; i <= na_; i++) {
    t = toks[i]
    if (t == "") continue
    if (t in isdim) activeset[t] = 1
    else prob[++np] = "Active dimensions lists an unknown dimension: " t
  }
  nact = 0
  for (i = 1; i <= nd; i++) if (dims[i] in activeset) act[++nact] = dims[i]
  if (nact == 0) prob[++np] = "no active dimensions found on the Snapshot line \"- Active dimensions:\""

  # Per-finding tallies.
  for (i = 1; i <= nf; i++) {
    id = fid[i]
    d = id
    sub(/-[0-9]+$/, "", d)
    s = sev[id]; c = conf[id]; e = eff[id]
    if (sevrank(s) > 3) { prob[++np] = id ": severity is not Critical, High, Medium, or Low"; continue }
    if (c != "Confirmed" && c != "Likely" && c != "Suspected") { prob[++np] = id ": confidence is not Confirmed, Likely, or Suspected"; continue }
    if (!(d in activeset)) { prob[++np] = id ": filed under " d ", which is not an active dimension, so it was not scored" ; continue }
    ok[id] = 1
    half = (c == "Suspected") ? 1 : 2
    if (s == "Low") low2[d] += half
    else ded2[d] += points(s) * half
    if (c == "Suspected") susp[d]++
    else cnt[d, s]++
    if (s == "Critical" && c != "Suspected") crit[d]++
  }

  # Dimension scores.
  num = 0; den = 0; totcrit = 0; floorcrit = 0; capnotes = ""
  for (k = 1; k <= nact; k++) {
    d = act[k]
    l2 = low2[d] + 0
    if (l2 > 20) l2 = 20
    t2 = ded2[d] + l2
    sc = (t2 >= 200) ? 0 : int((200 - t2) / 2)
    if (crit[d] >= 2 && sc > 59) { sc = 59; capnotes = capnotes "; " d " held at 59 (two or more Critical findings)" }
    else if (crit[d] == 1 && sc > 69) { sc = 69; capnotes = capnotes "; " d " held at 69 (one Critical finding)" }
    score[d] = sc
    num += weight[d] * sc
    den += weight[d]
    totcrit += crit[d]
    if (crit[d] > 0 && floor_[d] == "yes") floorcrit = 1
  }
  overall = (den > 0) ? int((2 * num + den) / (2 * den)) : 0
  if (totcrit >= 2 || floorcrit) {
    if (overall > 69) {
      overall = 69
      capnotes = capnotes "; overall held at 69 (" (floorcrit ? "a Critical finding in a floor dimension" : "two or more Critical findings") ")"
    }
  } else if (totcrit == 1 && overall > 79) {
    overall = 79
    capnotes = capnotes "; overall held at 79 (one Critical finding)"
  }
  sub(/^; /, "", capnotes)
  og = grade(overall)

  # Totals.
  split("Critical High Medium Low", sevs, " ")
  for (k = 1; k <= nact; k++) {
    d = act[k]
    for (j = 1; j <= 4; j++) tot[sevs[j]] += cnt[d, sevs[j]]
    tsusp += susp[d]
  }
  counts = "Critical " (tot["Critical"] + 0) ", High " (tot["High"] + 0) ", Medium " (tot["Medium"] + 0) ", Low " (tot["Low"] + 0) " (Suspected, not yet confirmed: " (tsusp + 0) ")"

  # Buckets.
  nfx = 0; nqw = 0; npn = 0; nvf = 0; nsc = 0; nbl = 0
  for (i = 1; i <= nf; i++) {
    id = fid[i]
    if (!(id in ok)) continue
    s = sev[id]; c = conf[id]; e = eff[id]
    sys_ = (related[id] ~ /SYS-[0-9]/) ? 0 : 1
    key = sevrank(s) "" sys_ "" effrank(e) " " id
    if (c == "Suspected") vf[++nvf] = sevrank(s) " " id "\t" id
    else if (s == "Critical" || s == "High") {
      fx[++nfx] = key "\t" id
      if (e == "S") qw[++nqw] = key "\t" id
      else pn[++npn] = key "\t" id
    }
    else if (s == "Medium") scd[++nsc] = id "\t" id
    else bl[++nbl] = id "\t" id
  }
  isort(fx, nfx); isort(qw, nqw); isort(pn, npn); isort(vf, nvf); isort(scd, nsc); isort(bl, nbl)

  # Block: score.
  print "#BLOCK score"
  if (quick) {
    printf "**Quick triage, not scored: %d Critical and %d High finding(s) confirmed or likely.** Quick mode works only the Critical-class cards; run a full audit for scores.\n\n", tot["Critical"], tot["High"]
    print "| Dimension | Critical | High | Medium | Low | Suspected |"
    print "|---|---:|---:|---:|---:|---:|"
    for (k = 1; k <= nact; k++) {
      d = act[k]
      printf "| %s %s | %d | %d | %d | %d | %d |\n", d, dname[d], cnt[d, "Critical"], cnt[d, "High"], cnt[d, "Medium"], cnt[d, "Low"], susp[d]
    }
  } else {
    label = partial ? "Partial score (" mode "): " : "Overall: "
    printf "**%s%d/100, Grade %s (%s)**\n\n", label, overall, og, glabel(og)
    print "| Dimension | Score | Grade | Weight | Critical | High | Medium | Low | Suspected |"
    print "|---|---:|---|---:|---:|---:|---:|---:|---:|"
    for (k = 1; k <= nact; k++) {
      d = act[k]
      printf "| %s %s | %d | %s | %.1f%% | %d | %d | %d | %d | %d |\n", d, dname[d], score[d], grade(score[d]), (den > 0 ? 100 * weight[d] / den : 0), cnt[d, "Critical"], cnt[d, "High"], cnt[d, "Medium"], cnt[d, "Low"], susp[d]
    }
    printf "| **Overall** | **%d** | **%s** | 100%% | %d | %d | %d | %d | %d |\n", overall, og, tot["Critical"], tot["High"], tot["Medium"], tot["Low"], tsusp
    print ""
    print "Caps applied: " (capnotes == "" ? "none" : capnotes) "."
  }
  if (meta["na"] != "" && meta["na"] != "none") print "Not applicable (not scored): " meta["na"] "."
  if (meta["notassessed"] != "" && meta["notassessed"] != "none") print "Not assessed in this run (not scored): " meta["notassessed"] "."
  print "Findings: " counts "."
  print "Computed by score.sh from the findings below (rules: references/protocol.md, Scoring)."

  # Block: fix-first.
  print "#BLOCK fix-first"
  if (nfx == 0) print "No Critical or High findings are confirmed or likely. Start with the Schedule bucket under Remediation plan, and confirm the Verify first items."
  for (i = 1; i <= nfx; i++) {
    id = payload(fx[i])
    printf "%d. [%s] %s - %s, effort %s. %s\n", i, id, title[id], sev[id], eff[id], first_sentence(impact[id])
  }

  # Block: plan.
  print "#BLOCK plan"
  print "- Quick wins (Critical or High, not Suspected, effort S): " join_ids(qw, nqw)
  print "- Plan now (Critical or High, not Suspected, effort M or L), in this order: " join_ids(pn, npn)
  print "- Verify first (Suspected; confirm against the code before acting): " join_ids(vf, nvf)
  print "- Schedule (Medium): " join_ids(scd, nsc)
  print "- Backlog (Low): " join_ids(bl, nbl)

  # Block: chat.
  print "#BLOCK chat"
  v = meta["verdict"]
  if (v ~ /^\{\{/) v = ""
  if (quick) {
    printf "%s: %d Critical, %d High. %s\n\n", quick_headline, tot["Critical"], tot["High"], v
    print "| Dimension | Critical | High | Suspected |"
    print "|---|---:|---:|---:|"
    for (k = 1; k <= nact; k++) { d = act[k]; printf "| %s | %d | %d | %d |\n", d, cnt[d, "Critical"], cnt[d, "High"], susp[d] }
  } else {
    printf "%s%s: %d/100 (Grade %s). %s\n\n", headline, (partial ? " (" mode ")" : ""), overall, og, v
    print "| Dimension | Score | Grade |"
    print "|---|---:|---|"
    for (k = 1; k <= nact; k++) { d = act[k]; printf "| %s %s | %d | %s |\n", d, dname[d], score[d], grade(score[d]) }
    printf "| **Overall** | **%d** | **%s** |\n", overall, og
  }
  print ""
  print "What to fix first:"
  if (nfx == 0) print "- nothing Critical or High; see the Remediation plan"
  for (i = 1; i <= nfx && i <= 5; i++) { id = payload(fx[i]); printf "%d. [%s] %s - %s, effort %s\n", i, id, title[id], sev[id], eff[id] }
  print ""
  print "Findings: " counts
  print "Full report: ./" report_file

  print "#BLOCK problems"
  for (i = 1; i <= np; i++) print prob[i]
}
