## Growi API
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

proc get(path: string): Response =
  var client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})
  var url = parseUri(URL)
  url.path = "_api/v3/page"
  let q = {"access_token": ACCESS_TOKEN, "path": path}
  let res = client.get(url ? q)
  return res

proc initData(path: string): Data =
  let res: Response = get(path)
  if res.status != $Http200:
    result.exist = false
    return
  # underscoreをobjectのfield名にできない仕様のせいで
  # stringを一部underscoreなしにする
  let jsonStr = res.body.multiReplace(
    ("\"_id\":", "\"id\":")
  )
  result.page = to(parseJson(jsonStr)["page"], Page)
  result.exist = true

if is_main_module:
  let data = initData(paramStr(1))
  if data.exist:
    echo data.page.revision.body
    echo data.page.revision.id
  else: echo "Page not exist"
