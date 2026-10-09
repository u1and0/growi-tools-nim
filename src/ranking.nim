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
import std/[uri,
  strutils,
  strformat,
  sets,
  json,
  httpclient,
  times,
]
import
  growiapi,
  helper,
  client,
  progress,
  ranks

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
  stderr.writeLine "ページ一覧を取得中..."
  let pages = getAllPageElement(src)
  stderr.writeLine &"{pages.len} ページを集計します"
  let t0 = epochTime()

  for i, p in pages:
    result.add Rank(
      path: p.path,
      id: p.id,
      liker: p.liker.len,
      seen: p.seenUsers.len,
      commentCount: p.commentCount,
      authors: authorCount(p.id),
    )
    showProgress(i+1, pages.len, t0)

proc run(dst = "", src = "/", top = 10) =
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
  import cligen
  clCfg.version = VERSION

  dispatch(run,
  cmdName = "ranking",
  help = {
    "src": "ランキング集計元ページパス(空なら全てのページのランキング)",
    "dst": "ランキング表示先ページパス(空なら標準出力に表示)",
    "top": "ランキング上位数(デフォルトでトップ10)",
  }
  )
