## Growi記事ランキング投稿
##
## usage:
##   $ ranking [SRC] [DST] [TOP]
##   $ ranking /From/Root /Ranking 5
##
## env: GROWI_URL, GROWI_ACCESS_TOKEN
## build: nim c -d:ssl -d:release ranking.nim
import std/[os, strutils, strformat, algorithm, json, httpclient, uri, sequtils, sets]
import client, growiapi

# ---------------------------------------------------------------- Growi API
# NOTE: Growi API v1 エンドポイントを想定。環境に合わせて調整すること。
type
  PageInfo = object
    exist: bool
    id, revisionId, body: string

# proc get(c: Client, endpoint: string,
#          params: openArray[(string, string)]): JsonNode =
#   var q = @params
#   q.add ("access_token", c.token)
#   let http = newHttpClient()
#   defer: http.close()
#   parseJson(http.getContent(&"{c.origin}/_api/{endpoint}?{encodeQuery(q)}"))
#
# proc postForm(c: Client, endpoint: string,
#               params: openArray[(string, string)]): JsonNode =
#   var q = @params
#   q.add ("access_token", c.token)
#   let http = newHttpClient(headers = newHttpHeaders(
#     {"Content-Type": "application/x-www-form-urlencoded"}))
#   defer: http.close()
#   parseJson(http.postContent(&"{c.origin}/_api/{endpoint}", encodeQuery(q)))
#
# proc getPage(c: Client, path: string): PageInfo =
#   try:
#     let p = c.get("pages.get", {"path": path})["page"]
#     result = PageInfo(exist: true,
#                       id: p["_id"].getStr,
#                       revisionId: p["revision"]["_id"].getStr,
#                       body: p["revision"]["body"].getStr)
#   except CatchableError:
#     result = PageInfo() # 存在しないページ
#
# proc post(c: Client, path: string, page: PageInfo, body: string): JsonNode =
#   if page.exist:
#     c.postForm("pages.update", {"body": body, "page_id": page.id,
#                                 "revision_id": page.revisionId})
#   else:
#     c.postForm("pages.create", {"body": body, "path": path})
#
# proc authorCount(c: Client, pageId: string): int =
#   var authors = initHashSet[string]()
#   let revs = c.get("revisions.list", {"page_id": pageId, "limit": "100"})
#   for r in revs["revisions"]:
#     let a = r.getOrDefault("author")
#     if a.isNil: continue
#     authors.incl(if a.kind == JObject: a{"_id"}.getStr else: a.getStr)
#   authors.len
#
# ------------------------------------------------------------------- Ranks
type
  Rank* = object
    path*, id*: string
    liker*, seen*, commentCount*, authors*: int

  Ranks* = seq[Rank]

  RankKey* = enum
    rkLiker, rkSeen, rkCommentCount, rkAuthors

proc value(r: Rank, k: RankKey): int =
  case k
  of rkLiker: r.liker
  of rkSeen: r.seen
  of rkCommentCount: r.commentCount
  of rkAuthors: r.authors

proc collect(c: Client, src: string): Ranks =
  let pages = c.get("pages.list", {"path": src, "limit": "10000"})["pages"]
  for p in pages:
    let id = p["_id"].getStr
    result.add Rank(path: p["path"].getStr, id: id,
                    liker: p["liker"].len,
                    seen: p["seenUsers"].len,
                    commentCount: p["commentCount"].getInt,
                    authors: c.authorCount(id))

proc sortBy*(ranks: var Ranks, k: RankKey) =
  ranks.sort(proc(a, b: Rank): int = cmp(a.value(k), b.value(k)), Descending)

proc convert*(ranks: Ranks, origin: string): seq[string] =
  ranks.mapIt(&"[{it.path}]({origin}/{it.id}) :heart:{it.liker} " &
              &":footprints:{it.seen} :speech_balloon:{it.commentCount} " &
              &":pencil2:{it.authors}")

proc shift*(before, after: seq[string]): seq[string] =
  ## beforeの各idについてafter内の位置と比較し、上/下/横/newの記号を返す
  let beforeRanks = before.mapIt(after.find(it))       # 未登場は -1
  for afterRank, beforeRank in beforeRanks:
    result.add:
      if beforeRank < 0: ":new:"
      elif beforeRank - afterRank > 0: ":arrow_upper_right:"
      elif beforeRank - afterRank < 0: ":arrow_lower_right:"
      else: ":arrow_right:"

proc order*(ranks: Ranks, top: int, ids: seq[string],
           origin: string): seq[string] =
  let topRanks = ranks[0 ..< min(top, ranks.len)]
  let afterRanks = topRanks.convert(origin)
  let arrows =
    if ids.len > 0: shift(ids, topRanks.mapIt(it.id))
    else: newSeq[string](top) # 初回: 矢印なし
  for i in 0 ..< min(arrows.len, afterRanks.len):
    result.add &"{i + 1}. {arrows[i]} {afterRanks[i]}"

proc readIds*(paragraph: string): seq[string] =
  ## 24桁の[a-f0-9]を抽出 (re.findall(r"[a-f0-9]{24}") 相当)
  proc isHex(ch: char): bool = ch in {'0'..'9', 'a'..'f'}
  var i = 0
  while i + 24 <= paragraph.len:
    if paragraph[i ..< i + 24].allIt(it.isHex):
      result.add paragraph[i ..< i + 24]
      i += 24
    else:
      inc i

# -------------------------------------------------------------------- main
proc run(dst, src: string, top: int) =
  let c = newClient()
  var ranks = c.collect(src)

  var rankPage: PageInfo
  var beforeChunks: seq[seq[string]]
  if dst.len > 0:
    rankPage = c.getPage(dst)
    if rankPage.exist:
      let ids = readIds(rankPage.body)
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
    pageBody.add ranks.order(top, chunk, c.origin).join("\n")

  if dst.len == 0:
    echo pageBody # test出力のみ
    return
  echo c.post(dst, rankPage, pageBody)

when isMainModule:
  let a = commandLineParams()
  run(dst = (if a.len > 1: a[1] else: ""),
      src = (if a.len > 0: a[0] else: "/"),
      top = (if a.len > 2: parseInt(a[2]) else: 10))
