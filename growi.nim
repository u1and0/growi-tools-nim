import std/uri
import std/os
import std/httpclient
import std/json
import strutils
const ACCESS_TOKEN = getEnv("GROWI_ACCESS_TOKEN") # Get token from https://demo.growi.org/me
const URL = getEnv("GROWI_URL") # https://demo.growi.org/

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

proc get(path: string): Response =
  var client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})
  var url = parseUri(URL)
  url.path = "_api/v3/page"
  let q = {
    "access_token": ACCESS_TOKEN,
    "path": path,
  }
  let res = client.get(url ? q)
  return res

proc initData(path: string): Data =
  let res: Response = get(path)
  # underscoreをobjectのfield名にできない仕様のせいで
  # stringを一部underscoreなしにする
  let jsonStr = res.body.multiReplace(
    ("\"_id\":", "\"id\":")
  )
  to(parseJson(jsonStr), Data)

if is_main_module:
  let data = initData(paramStr(1))
  echo data.page.revision.body
  echo data.page.revision.id
