import os, osproc, streams
const exe = "/usr/bin/pdftotext"
if not fileExists(exe):
  echo exe & " is not found"
  quit(1)
block: # ちゃんとシステムプロセスから呼ぶやり方
  var p: Process
  defer: p.close
  # `pdftotext test/*.pdf -` を実行
  p = startProcess(exe, "test", @["V-4-251 C　サーバルームに関する基準.pdf", "-"])
  # p = startProcess(exe, "test/V-4-251 C　サーバルームに関する基準.pdf", @["-"])
  echo "process ID: " & $p.processID
  let outstr = p.outputStream # 標準出力をoutstrへ格納
  var line: string = ""
  while outstr.readLine(line): # outstrを1行ずつ出力
    echo line
  echo p.waitForExit()


# 1行書き
echo "execしてみた" & execProcess("pdftotext 'test/V-4-251 C　サーバルームに関する基準.pdf' -")
