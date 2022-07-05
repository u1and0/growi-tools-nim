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

type
  ## _api/v3/page で取得できるJSONオブジェクトのrevision要素
  Revision = object
    id: string
    body: string
    pageId: string

  ## _api/v3/page で取得できるJSONオブジェクトのcreator要素
  Creator = object
    name: string
    username: string

  ## _api/v3/page で取得できるJSONオブジェクトのpage要素
  Page = object
    id: string
    path: string
    revision: Revision
    creator: Creator

  ## _api/v3/page で取得できるJSONオブジェクトとページの存在、エラーメッセージ
  MetaPage = object
    page: Page
    exist: bool
    error: string

  ## _api/pages.list で取得できるJSONオブジェクトのpages要素
  ClassicalPage = tuple[
    id, path, creator, revision: string,
    liker, seenUsers: seq[string],
    commentCount: int
    ]
  Pages = seq[ClassicalPage]

proc create(self: MetaPage, body: string): Response =
  ## パスの内容へbodyを書き込む
  let param = %* {
    "body": body,
    "path": self.page.path,
    "access_token": TOKEN,
  }
  CLIENT.request(URI / "_api/v3/pages", httpMethod = HttpPost, body = $param)

proc update(self: MetaPage, body: string): Response =
  ## パスの内容をbodyで更新する
  if body == self.page.revision.body:
    var e: ref HttpRequestError
    new(e)
    e.msg = "{\"error\": \"更新前後の内容が同じなので、更新しませんでした。\"}"
    raise e
  let param = %* {
    "page_id": self.page.id,
    "revision_id": self.page.revision.id,
    "body": body,
    "access_token": TOKEN,
  }
  CLIENT.request(URI / "_api/pages.update", httpMethod = HttpPost, body = $param)

proc post(self: MetaPage, body: string): Response =
  ## 指定パスに
  ## ページが存在すれば_update(),
  ## ページが存在しなければ_create()
  ## で引数bodyの内容を上書き/書込みする。
  if self.exist:
    self.update(body)
  else:
    self.create(body)

proc get(self: MetaPage): Response =
  ## パスのページをJSONで取得する
  let q = {"access_token": TOKEN, "path": self.page.path}
  CLIENT.get(URI / "_api/v3/page" ? q)

proc list(self: MetaPage): Response =
  ## パス配下のpage情報を取得する
  let q = {"access_token": TOKEN, "path": self.page.path}
  CLIENT.get(URI / "_api/pages.list" ? q)

proc tree(self: MetaPage): seq[string] =
  let res = self.list()
  # underscoreをobjectのfield名にできない仕様のせいで
  # stringを一部underscoreなしにする
  let jsonStr = res.body.multiReplace(
    ("\"_id\":", "\"id\":")
  )
  let pages = jsonStr.parseJson()["pages"].to(Pages)
  result = collect(newSeq):
    for item in pages: item.path

proc initMetaPage(path: string): MetaPage =
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

  let res: Response = result.get()
  case res.status:
    of $Http200:
      # underscoreをobjectのfield名にできない仕様のせいで
      # stringを一部underscoreなしにする
      let jsonStr = res.body.multiReplace(
        ("\"_id\":", "\"id\":")
      )
      result.page = to(parseJson(jsonStr)["page"], Page)
      result.exist = true
    else:
      result.exist = false
      result.error = $parseJson(res.body)["errors"]
      result.page.path = path


type
  Author = tuple[name, username, createdAt, id: string]

  Doc = tuple[id, pageId, body: string, author: Author]
  Docs = seq[Doc]
  Revisions = tuple[docs: Docs, page, totalDocs: int]

  MetaRevisions = object
    revisions: Revisions
    pageId: string
    page: int

proc get(self: MetaRevisions): Response =
  let q = {"access_token": TOKEN, "pageId": self.pageId, "page": $self.page}
  CLIENT.get(URI / "_api/v3/revisions/list" ? q)

proc initRevisionHistory(id: string): MetaRevisions =
  result = MetaRevisions()
  result.page = 0
  result.pageId = id

  let res = result.get()
  # underscoreをobjectのfield名にできない仕様のせいで
  # stringを一部underscoreなしにする
  let jsonStr = res.body.multiReplace(
    ("\"_id\":", "\"id\":")
  )
  result.revisions = to(parseJson(jsonStr), Revisions)

proc echoHelp(code: int) =
  echo """Get Growi Page info by Growi API

  Uasge:
    # GET page body
    growi /path/to/page
    # POST page body
    growi /path/to/page "my test\nbody"
  """
  quit(code)

# ここからCLI実装
proc growiApiGet(verbose = false, args: seq[string]): int =
  if len(args) != 1:
    echo "usage: growiapi get PATH"
    return 1
  let metaPage = initMetaPage(args[0])
  if verbose:
    echo pretty( %* metaPage.page)
  else:
    echo metaPage.page.revision.body
  return 0

proc growiApiPost(verbose = false, args: seq[string]): int =
  if len(args) != 2:
    echo "usage: growiapi post PATH BODY"
    return 1
  let metaPage = initMetaPage(args[0])
  let body: string = if fileExists(args[1]): readFile(args[1]) else: args[1]
  let res: Response = metaPage.post(body)
  if verbose:
    echo res.body.parseJson().pretty()
  else:
    discard res
  return 0

proc growiApiUpdate(verbose = false, args: seq[string]): int =
  if len(args) != 2:
    echo "usage: growiapi update PATH BODY"
    return 1
  let metaPage = initMetaPage(args[0])
  if not metaPage.exist:
    echo "error: not exist path. try `growiapi create PATH BODY`."
    return 2
  let body: string = if fileExists(args[1]): readFile(args[1]) else: args[1]
  let res: Response = metaPage.update(body)
  if verbose:
    echo res.body.parseJson().pretty()
  else:
    discard res
  return 0

proc growiApiCreate(verbose = false, args: seq[string]): int =
  if len(args) != 2:
    echo "usage: growiapi create PATH BODY"
    return 1
  let metaPage = initMetaPage(args[0])
  if metaPage.exist:
    echo "error: exist path. try `growiapi update PATH BODY`."
    return 2
  let body: string = if fileExists(args[1]): readFile(args[1]) else: args[1]
  let res: Response = metaPage.create(body)
  if verbose:
    echo res.body.parseJson().pretty()
  else:
    discard res
  return 0

proc growiApiList(verbose = false, args: seq[string]): int =
  if len(args) != 1:
    echo "usage: growiapi list PATH"
    return 1
  let metaPage = initMetaPage(args[0])
  let res: Response = metaPage.list()
  if verbose:
    echo res.body.parseJson().pretty()
  else:
    for i in metaPage.tree():
      echo i
  return 0

proc growiApiRev(verbose = false, args: seq[string]): int =
  if len(args) != 1:
    echo "usage: growiapi rev PATH"
    return 1
  let metaPage = initMetaPage(args[0])
  let rev = initRevisionHistory(metaPage.page.id)
  echo $rev
  return 0

when is_main_module:
  # var args: seq[string]
  # var opts: Opts
  # for kind, key, val in getopt(commandLineParams()):
  #   case kind
  #   of cmdArgument:
  #     args.add(key)
  #   of cmdLongOption, cmdShortOption:
  #     case key
  #     of "help", "h": echoHelp(0)
  #     of "list", "l": opts.list = true
  #     of "revision", "r": opts.rev = true
  #   of cmdEnd: assert(false)
  # if args == @[]: echoHelp(1)

  import cligen
  clCfg.version = "v0.1.0"

  dispatchMulti(
    [growiApiGet, cmdName = "get", help = "growiapi get PATH"],
    [growiApiPost, cmdName = "post", help = "growiapi post PATH BODY"],
    [growiApiUpdate, cmdName = "update", help = "growiapi update PATH BODY"],
    [growiApiCreate, cmdName = "create", help = "growiapi create PATH BODY"],
    [growiApiList, cmdName = "list", help = "growiapi list PATH"],
    [growiApiRev, cmdName = "rev", help = "growiapi rev PATH"],
  )

  # let metaPage = initMetaPage(args[0])
  # if opts.list and metaPage.exist:
  #   echo metaPage.list().body.parseJson().pretty()
  # elif opts.rev and metaPage.exist:
  #   let rev = initRevisionHistory(metaPage.page.id)
  #   echo $rev
  # elif args.len() == 1 and metaPage.exist:
  #   # GET method
  #   echo metaPage.page.revision.body
  # elif args.len() == 2:
  #   # POST method
  #   let body: string = if fileExists(args[1]): readFile(args[1]) else: args[1]
  #   let res: Response = metaPage.post(body)
  #   echo res.status & "\n" & res.body
  # else:
  #   echo metaPage
  #   echoHelp(1)
