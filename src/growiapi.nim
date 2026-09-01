## Get Growi Page info by Growi API
##
## Uasge:
##   # GET page body
##   growi /path/to/page
##   # POST page body
##   growi /path/to/page "my test\nbody"
import std/uri
import std/os
import std/httpclient
import std/json
import strutils
import sugar
import tables
import strformat

## Get token from https://demo.growi.org/me
let TOKEN = getEnv("GROWI_ACCESS_TOKEN")
if TOKEN == "":
  var e: ref KeyError
  new(e)
  e.msg = "アクセストークンが設定されていません"
  raise e
## https://demo.growi.org/
let URI = getEnv("GROWI_URL", "http://localhost:3000").parseUri()
let CLIENT = newHttpClient()
CLIENT.headers = newHttpHeaders({"Content-Type": "application/json"})

## jsonReplace(): jsonフィールドを任意に変更する
# underscoreをobjectのfield名にできない仕様のせいで
# stringを一部underscoreなしにする
proc jsonReplace*(body: string): string =
  return body.multiReplace(
    ("\"_id\":", "\"id\":")
  )

type
  ## _api/v3/page で取得できるJSONオブジェクトのrevision要素
  Revision* = object
    id*: string
    body*: string
    pageId*: string

  ## _api/v3/page で取得できるJSONオブジェクトのcreator要素
  Creator* = object
    name*: string
    username*: string

  Page* = object ## _api/v3/page で取得できるJSONオブジェクトのpage要素
    id*: string
    path*: string
    revision*: Revision
    creator*: Creator

  MetaPage* = object ## _api/v3/page で取得できるJSONオブジェクトとページの存在、エラーメッセージ
    page*: Page
    limit: int
    exist: bool
    error: string

proc create*(self: MetaPage, body: string): Response =
  ## パスの内容へbodyを書き込む
  let param = %* {
    "body": body,
    "path": self.page.path,
    "access_token": TOKEN
  }
  CLIENT.request(URI / "_api/v3/page", httpMethod = HttpPost, body = $param)

proc update*(self: MetaPage, body: string): Response =
  ## パスの内容をbodyで更新する
  if body == self.page.revision.body:
    var e: ref HttpRequestError
    new(e)
    e.msg = "{\"error\": \"更新前後の内容が同じなので、更新しませんでした。\"}"
    raise e
  let param = %* {
    "pageId": self.page.id,
    "revisionId": self.page.revision.id,
    "body": body,
    "access_token": TOKEN,
  }
  CLIENT.request(URI / "_api/v3/page", httpMethod = HttpPut, body = $param)

proc post*(self: MetaPage, body: string): Response =
  ## 指定パスに
  ## ページが存在すれば_update(),
  ## ページが存在しなければ_create()
  ## で引数bodyの内容を上書き/書込みする。
  if self.exist:
    self.update(body)
  else:
    self.create(body)

proc get*(self: MetaPage): Response =
  ## パスのページ内容をJSONで取得する
  let q = {"access_token": TOKEN, "path": self.page.path}
  CLIENT.get(URI / "_api/v3/page" ? q)

proc getPages*(
  path: string = "/",
  limit: int = 20,
  page: int = 1,
  ): Response =
  ## ```sh
  ## curl "http://192.168.160.118:3000/_api/v3/pages/list?access_token=$GROWI_ACCESS_TOKEN&path=/&page=872&limit=1" | jq -r
  ## ```
  ##
  ## これで最初に作ったページを表示する(total count 872のとき)
  ##
  ## ```sh
  ## curl "http://192.168.160.118:3000/_api/v3/pages/list?access_token=$GROWI_ACCESS_TOKEN&path=/&page=1&limit=1" | jq -r
  ## ```
  ##
  ## これで最後に作られたページを表示する
  ##
  ## limit: 表示するページの数、default 20, max 100
  ## path: 探索するページのルート
  ## page: オフセットと関係する。 だいたい offset = page x limit っぽい。
  let q = {
    "access_token": TOKEN,
    "path": path,
    "limit": $limit,
    "page": $page,
  }
  CLIENT.get(URI / "_api/v3/pages/list" ? q)

# pages.list がdeprecated になったようだ。使えない。
# 相当するAPIも見つからない
# proc list*(self: MetaPage): Response =
#   ## パス配下のpage情報を取得する
#   let q = {
#     "access_token": TOKEN,
#     "path": self.page.path,
#     "limit": $self.limit
#   }
#   CLIENT.get(URI / "_api/v3/pages/list" ? q)

proc initMetaPage*(path: string, limit = 50): MetaPage =
  ## GrowiへのAPIアクセス
  ## # Usage
  ## 環境変数に `_GROWI_ACCESS_TOKEN` `GROWI_URL` をセットする必要がある。
  ##
  ## `GROWI_ACCESS_TOKEN`を設定しない場合、KeyErrorを吐いてプログラムは終了する。
  ## `GROWI_URL`を設定しない場合、"http://localhost:3000"が割り当てられる。
  ##
  ## # Example
  ## metaPage = initMetaPage("/user/myname")
  ##
  ## metaPage.exist: ページが存在するならTrue
  ## metaPage.get(): パスのページをJSONで取得する
  ## metaPage.post(body): パスの内容へbodyを書き込むか上書きする
  ## metaPage.list(): パス配下の情報をJSONで取得する
  result = MetaPage()
  result.page.path = path
  result.limit = limit

  let res: Response = result.get()
  case res.status:
    of $Http200:
      let jsonStr = res.body.jsonReplace()
      result.page = to(parseJson(jsonStr)["page"], Page)
      result.exist = true
    else:
      result.exist = false
      result.error = $parseJson(res.body)["errors"]
      result.page.path = path

## _api/pages.list で取得できるJSONオブジェクトのpages要素
## v3からは _api/v3/pages/list でも取得できる
type PageElement* = object
  id*, path*, creator*, revision*: string
  liker*, seenUsers*: seq[string]
  commentCount*: int

type PageList* = object
  pages*: seq[PageElement]
  totalCount*, offset*, limit*: int


# proc initClassicalPage*(path: string): ClassicalPage =
#   let metaPage = initMetaPage(path, limit = 1)
#   let res: Response = metaPage.list()
#   let jsonStr = res.body.jsonReplace()
#   result = jsonStr.parseJson()["pages"][0].to(ClassicalPage)

# proc tree*(self: MetaPage): seq[string] =
#   let res = self.list()
#   let jsonStr = res.body.jsonReplace()
#   echo "Debug printing from Growi" & jsonStr
#   let pages = jsonStr.parseJson()["pages"].to(Pages)
#   result = collect(newSeq):
#     for item in pages: item.path

type
  Author* = object
    name, username, createdAt, id: string
  Doc* = object
    id*, pageId*, body*: string
    author*: Author
  Revisions* = object
    docs*: seq[Doc]
    page*: int
    totalDocs*: int
  MetaRevisions* = object
    revisions: Revisions
    pageId: string
    page: int

proc get*(self: MetaRevisions): Response =
  let q = {"access_token": TOKEN, "pageId": self.pageId, "page": $self.page}
  CLIENT.get(URI / "_api/v3/revisions/list" ? q)

proc chain*(self: MetaRevisions): OrderedTable[Doc.id, Doc.body] =
  collect(initOrderedTable(5)):
    for doc in self.revisions.docs: {doc.id: doc.body}

proc authors*(self: MetaRevisions): seq[Author.id] =
  for doc in self.revisions.docs:
    let a = try: doc.author.id except KeyError: continue
    result.add(a)

proc initMetaRevisions*(id: string): MetaRevisions =
  result = MetaRevisions()
  result.page = 0
  result.pageId = id

  let res = result.get()
  let jsonStr = res.body.jsonReplace()
  result.revisions = jsonStr.parseJson().to(Revisions)


# ヘルパー関数群

proc postProcessing(res: Response, v: bool): int =
  ## レスポンス取得後、詳細表示するならレスポンスボディを表示
  ## ステータスが200番台なら正常終了、
  ## そうでなければステータスコードとボディを表示して異常終了
  if v:
    try:
      echo res.body.parseJson().pretty()
    except JsonParsingError:
      echo res.body

  if res.status.startsWith("2"):
    return 0
  else:
    if not v:
      stderr.writeLine "error: API returned ", res.status
      stderr.writeLine res.body
      return 4

proc parseBody(s: string): string =
  ## bodyがファイルパスであれば、ファイルの内容を読む
  ## そうでなければ文字列としてセット
  if fileExists(s):
    return readFile(s)
  return s


# CLI実装
proc subcmdGet(verbose = false, args: seq[string]): int =
  if len(args) != 1:
    echo "usage: growiapi get PATH"
    return 1
  let metaPage = initMetaPage(args[0])
  if verbose:
    echo pretty( %* metaPage.page)
  else:
    echo metaPage.page.revision.body
  return 0

proc subcmdPost(verbose = false, args: seq[string]): int =
  if len(args) != 2:
    echo "usage: growiapi post PATH BODY"
    return 1

  let metaPage = initMetaPage(args[0])
  let body = parseBody(args[1])
  let res: Response = metaPage.post(body)

  postProcessing(res, verbose)

proc subcmdUpdate(verbose = false, args: seq[string]): int =
  # 引数がなければ終了
  if len(args) != 2:
    echo "usage: growiapi update PATH BODY"
    return 1

  # ページが存在しなければ終了j
  let metaPage = initMetaPage(args[0])
  if not metaPage.exist:
    echo "error: not exist path. try `growiapi create PATH BODY`."
    return 2

  let body = parseBody(args[1])
  let res: Response = metaPage.update(body)

  postProcessing(res, verbose)

proc subcmdCreate(verbose = false, args: seq[string]): int =
  # 引数がなければ終了
  if len(args) != 2:
    echo "usage: growiapi create PATH BODY"
    return 1

  # 同一ページが存在すればupdateを使うように案内して終了
  let metaPage = initMetaPage(args[0])
  if metaPage.exist:
    echo "error: exist path. try `growiapi update PATH BODY`."
    return 2

  let body = parseBody(args[1])
  # タイムアウト・通信エラー
  let res: Response =
    try:
      metaPage.create(body)
    except CatchableError as e:
      stderr.writeLine "error: request failed:", e.msg
      return 3

  postProcessing(res, verbose)


# proc subcmdList(verbose = false, args: seq[string]): int =
#   if len(args) != 1:
#     echo "usage: growiapi list PATH"
#     return 1
#   let metaPage = initMetaPage(args[0])
#   let res: Response = metaPage.list()
#   if verbose:
#     echo res.body.parseJson().pretty()
#   else:
#     for i in metaPage.tree():
#       echo i
#   return 0

proc subcmdRev(verbose = false, authors = false, args: seq[string]): int =
  if len(args) != 1:
    echo "usage: growiapi rev PATH"
    return 1
  let metaPage = initMetaPage(args[0])
  let rev = initMetaRevisions(metaPage.page.id)
  if verbose:
    echo pretty( %*rev)
  elif authors:
    echo rev.authors()
  else:
    for id, body in rev.chain():
      echo &"\n========{id}========\n"
      echo body
  return 0

proc subcmdGetPages(verbose = false, args: seq[string]): int =
  ## PATH下のページをLIMIT件まで表示する
  ## ただし、OFFSETで表示開始位置をシフトできる
  if len(args) > 4:
    echo "usage: growiapi rev PATH [LIMIT] [OFFSET]"
    return 1


  # デフォルトパラメータを使うので、引数の数に応じて渡す変数が異なる
  let res = case args.len
    of 0: getPages()
    of 1: getPages(args[0])
    of 2:
      let limit = parseInt(args[1])
      getPages(args[0], limit)
    else:
      let (limit, pages) = (parseInt(args[1]), parseInt(args[2]))
      getPages(args[0], limit, pages)

  if verbose:
    echo res.body.parseJson().pretty()
  else: # pages プロパティのみ表示
    echo pretty( %* res.body.parseJson()["pages"])

when is_main_module:
  import cligen
  clCfg.version = "v0.1.3r"

  dispatchMulti(
    [subcmdGet, cmdName = "get", help = "growiapi get PATH"],
    [subcmdPost, cmdName = "post", help = "growiapi post PATH BODY"],
    [subcmdUpdate, cmdName = "update", help = "growiapi update PATH BODY"],
    [subcmdCreate, cmdName = "create", help = "growiapi create PATH BODY"],
    # [subcmdList, cmdName = "list", help = "growiapi list PATH"],
    [subcmdRev, cmdName = "rev", help = "growiapi rev PATH"],
    [subcmdGetPages, cmdName = "pages", help = "growiapi pages PATH [LIMIT] [OFFSET]"],
  )
