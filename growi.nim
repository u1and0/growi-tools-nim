## Get Growi Page info by Growi API
##
## Uasge:
##   growi /path/to/page
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

proc create(d: Data, body: string): Response =
  ## data.create method
  let client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})
  var url = parseUri(URL)
  url.path = "_api/v3/pages"
  let param = %* {
    "body": body,
    "path": d.page.path,
    "access_token": ACCESS_TOKEN
  }
  client.request(url, httpMethod = HttpPost, body = $param)


proc get(path: string): Response =
  ## Get page body
  var client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})
  var url = parseUri(URL)
  url.path = "_api/v3/page"
  let q = {"access_token": ACCESS_TOKEN, "path": path}
  client.get(url ? q)

proc initData(path: string): Data =
  let res: Response = get(path)
  case res.status:
    of $Http404:
      result.page.path = path
      result.exist = false
      result.error = $parseJson(res.body)["errors"]
    of $Http200:
      # underscoreをobjectのfield名にできない仕様のせいで
      # stringを一部underscoreなしにする
      let jsonStr = res.body.multiReplace(
        ("\"_id\":", "\"id\":")
      )
      result.page = to(parseJson(jsonStr)["page"], Page)
      result.exist = true
    else:
      echo "none"

if is_main_module:
  let data = initData(paramStr(1))
  if data.exist and paramCount() == 1:
    # GET method
    echo data.page.revision.body
  elif paramCount() == 2:
    # POST method
    if data.exist:
      var e: ref HttpRequestError
      new(e)
      e.msg = "already exist"
      raise e
    let res = data.create(paramStr(2))
    echo res.body
  else:
    echo pretty(%data)
    echo data.error
