import std/[strformat, strutils, times, terminal]

const BarWidth = 20

proc mmss(sec: float): string =
  let s = int(sec)
  &"{s div 60:02}:{s mod 60:02}"

proc showProgress*(done, total: int, t0: float) =
  ## stderr に進捗表示。ttyは同一行を上書き、非ttyは10行ごとに1行出力
  let tty = stderr.isatty
  let mod10 = done mod 10 != 0
  let notTotal = done != total
  if not tty and mod10 and notTotal:
    return

  let
    filled = BarWidth * done div total
    bar = "#".repeat(filled) & '-'.repeat(BarWidth - filled)
    percent = done * 100 div total

    elapsed = epochTime() - t0
    elapsedText = mmss(elapsed)

    eta = elapsed / done.float * (total - done).float
    etaText = mmss(eta)

    line = &"[{bar}] {percent:>3}% {done}/{total} {elapsedText} ETA {etaText}"

  if tty:
    stderr.write "\r", line
    if done == total: stderr.write "\n"
  else:
    stderr.writeLine line
  stderr.flushFile
