## Growi記事ランキング投稿
##
## usage:
##   $ ranking [SRC] [DST] [TOP]
##   $ ranking /growi/source/path /upload/path 5
##
##   SRC: default "". if empty, print as stdout.
##   DST: default "/". The Growi root page.
##   TOP: default 10.
##
## env: GROWI_ACCESS_TOKEN, GROWI_URL (client.nim が読込)
## build: nim c -d:ssl -d:release ranking.nim
import std/[uri, os, strutils, strformat, sets, json, httpclient]
import growiapi, helper, client
import ranks

proc authorCount(pageId: string): int =
  ## 改版履歴(最大100件)の編集者数
  let res = MetaRevisions().get(pageId)
  if res.status != $Http200:
    stderr.writeLine &"revisions error: {pageId} {res.status}"
    return 0
  let revs = res.body.jsonReplace().parseJson()["revisions"].to(Revisions)
  var authors = initHashSet[string]()
  for r in revs:
    authors.incl r.author.name
  authors.len

proc collect(src: string): Ranks =
  for p in getAllPageElement(src):
    result.add Rank(path: p.path, id: p.id,
                    liker: p.liker.len,
                    seen: p.seenUsers.len,
                    commentCount: p.commentCount,
                    authors: authorCount(p.id))

proc run(dst, src: string, top: int) =
  var ranks = collect(src)
  let origin = ($URI).strip(leading = false, chars = {'/'})

  # 過去のランキングページの読み込み (未作成ならbodyは空 -> ids空)
  var rankPage: MetaPage
  var beforeChunks: seq[seq[string]]
  if dst.len > 0:
    rankPage = initMetaPage(dst)
    let ids = readIds(rankPage.page.revision.body)
    for i in countup(0, ids.high, top):
      beforeChunks.add ids[i ..< min(i + top, ids.len)]

  let elements = [
    (&"# :heart:ライクが多いランキングトップ{top}\n\n", rkLiker),
    (&"\n\n# :footprints:足跡が多いランキングトップ{top}\n\n",
        rkSeen),
    (&"\n\n# :speech_balloon:コメントが多いランキングトップ{top}\n\n",
        rkCommentCount),
    (&"\n\n# :pencil2:編集者が多いランキングトップ{top}\n\n",
        rkAuthors),
  ]

  var pageBody = ""
  for n, (title, key) in elements:
    ranks.sortBy(key)
    let chunk = if n < beforeChunks.len: beforeChunks[n] else: @[]
    pageBody.add title
    pageBody.add ranks.order(top, chunk, origin).join("\n")

  if dst.len == 0:
    echo pageBody # test出力のみ
    return
  try:
    let res = rankPage.post(pageBody)
    echo res.status, "\n", res.body
  except HttpRequestError as e:
    stderr.writeLine e.msg # 更新前後で内容が同じ場合など

when isMainModule:
  let a = commandLineParams()
  run(dst = (if a.len > 1: a[1] else: ""), # 空の場合は標準出力へ
    src = (if a.len > 0: a[0] else: "/"), # 基本的に全てのページのランキング
    top = (if a.len > 2: parseInt(a[2]) else: 10)) # デフォルトでトップ10
