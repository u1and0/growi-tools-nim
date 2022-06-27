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
## Get token from https://demo.growi.org/me
const ACCESS_TOKEN = getEnv("GROWI_ACCESS_TOKEN")
## https://demo.growi.org/
const URL = getEnv("GROWI_URL")

type
  Revision = object
    id: string
    body: string
    pageId: string

  Creator = object
    name: string
    username: string
    status: int

  Page = object
    id: string
    path: string
    revision: Revision
    creator: Creator

  Data = object
    page: Page
    exist: bool
    error: string

proc create(self: Data, body: string): Response =
  ## data.create method
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
  ## data.update method
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

proc get(self: Data): Response =
  ## Get page body
  var client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})
  var url = parseUri(URL)
  url.path = "_api/v3/page"
  let q = {"access_token": ACCESS_TOKEN, "path": self.page.path}
  client.get(url ? q)

proc initData(path: string): Data =
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

if is_main_module:
  let data = initData(paramStr(1))
  if data.exist and paramCount() == 1:
    # GET method
    echo data.page.revision.body
  elif paramCount() == 2:
    # POST method
    var res: Response
    if data.exist:
      res = data.update(paramStr(2))
    else:
      res = data.create(paramStr(2))
    if res.status == $Http200:
      echo res.body
    else:
      echo res.status & "\n" & res.body
  else:
    echo pretty(%data)
    echo data.error
