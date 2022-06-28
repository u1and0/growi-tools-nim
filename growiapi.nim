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
import parseopt
## Get token from https://demo.growi.org/me
const ACCESS_TOKEN = getEnv("GROWI_ACCESS_TOKEN")
## https://demo.growi.org/
const URL = getEnv("GROWI_URL")
const VERSION = "v0.1.0"

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
    status: int

  ## _api/v3/page で取得できるJSONオブジェクトのpage要素
  Page = object
    id: string
    path: string
    revision: Revision
    creator: Creator

  ## _api/v3/page で取得できるJSONオブジェクトとページの存在、エラーメッセージ
  Data = object
    page: Page
    exist: bool
    error: string

  Opts = tuple
    list: bool

proc create(self: Data, body: string): Response =
  ## パスの内容へbodyを書き込む
  let client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})
  var url = parseUri(URL)
  url.path = "_api/v3/pages"
  let param = %* {
    "body": body,
    "path": self.page.path,
    "access_token": ACCESS_TOKEN
  }
  client.request(url, httpMethod = HttpPost, body = $param)

proc update(self: Data, body: string): Response =
  ## パスの内容をbodyで更新する
  if body == self.page.revision.body:
    var e: ref HttpRequestError
    new(e)
    e.msg = "{\"error\": \"更新前後の内容が同じなので、更新しませんでした。\"}"
    raise e
  let client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})
  var url = parseUri(URL)
  url.path = "_api/pages.update"
  let param = %* {
    "page_id": self.page.id,
    "revision_id": self.page.revision.id,
    "body": body,
    "access_token": ACCESS_TOKEN
  }
  client.request(url, httpMethod = HttpPost, body = $param)

proc post(self: Data, body: string): Response =
  ## 指定パスに
  ## ページが存在すれば_update(),
  ## ページが存在しなければ_create()
  ## で引数bodyの内容を上書き/書込みする。
  if self.exist:
    self.update(body)
  else:
    self.create(body)

proc get(self: Data): Response =
  ## パスのページをJSONで取得する
  ## prop_access=True でJSONオブジェクトをデフォルトの辞書ではなく
  ## ドットプロパティアクセスできるSimpleNamespaceの形式で取得する。
  ## usage:
  ##     page = Page("...")
  ##     page.get(0) => 普通のJSONオブジェクト
  ##     page.get(1) => Pythonコンソールにてドットプロパティアクセス
  var client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})
  var url = parseUri(URL)
  url.path = "_api/v3/page"
  let q = {"access_token": ACCESS_TOKEN, "path": self.page.path}
  client.get(url ? q)

proc list(self: Data): Response =
  ## パス配下のpage情報を取得する
  var client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})
  var url = parseUri(URL)
  url.path = "_api/pages.list"
  let q = {"access_token": ACCESS_TOKEN, "path": self.page.path}
  client.get(url ? q)

proc initData(path: string): Data =
  ## GrowiへのAPIアクセス
  ## # Usage
  ## 環境変数に `_GROWI_ACCESS_TOKEN` `GROWI_URL` をセットする必要がある。
  ## Pythonコンソール上で行うには、

  ## >>> import os
  ## >>> os.environ["GROWI_ACCESS_TOKEN"] = "****"
  ## >>> os.environ["GROWI_URL"] = "http://192.168.***.***:3000"

  ## `GROWI_ACCESS_TOKEN`を設定しない場合、KeyErrorを吐いてプログラムは終了する。
  ## `GROWI_URL`を設定しない場合、"http://localhost:3000"が割り当てられる。

  ## # Example
  ## data = initData("/user/myname")

  ## data.exist: ページが存在するならTrue
  ## data._json: data.get()で返ってくるJSONオブジェクト
  ##             ドットプロパティアクセスできる
  ## data.get(): パスのページをJSONで取得する
  ## data.post(body): パスの内容へbodyを書き込むか上書きする
  ## data.list(): パス配下の情報をJSONで取得する
  var data = Data()
  data.page.path = path
  let res: Response = data.get()
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

proc echoHelp(code: int) =
  echo """Get Growi Page info by Growi API

  Uasge:
    # GET page body
    growi /path/to/page
    # POST page body
    growi /path/to/page "my test\nbody"
  """
  quit(code)

proc echoVersion() =
  echo "growiapi ", VERSION
  quit()

if is_main_module:
  var args: seq[string]
  var opts: Opts
  for kind, key, val in getopt(commandLineParams()):
    case kind
    of cmdArgument:
      args.add(key)
    of cmdLongOption, cmdShortOption:
      case key
      of "help", "h": echoHelp(0)
      of "version", "v": echoVersion()
      of "list", "l": opts.list = true
    of cmdEnd: assert(false)
  if args == @[]: echoHelp(1)

  let data = initData(args[0])
  if opts.list and data.exist:
    echo data.list().body
  elif args.len() == 1 and data.exist:
    # GET method
    echo data.page.revision.body
  elif args.len() == 2:
    # POST method
    let res: Response = data.post(args[1])
    echo res.status & "\n" & res.body
  else:
    echo pretty(%data)
    echo data.error
