import std/uri
import std/os
import std/httpclient
import std/json
import strutils
const ACCESS_TOKEN = getEnv("GROWI_ACCESS_TOKEN") # Get token from https://demo.growi.org/me
const URL = getEnv("GROWI_URL") # https://demo.growi.org/

  # type Page = object
  #   path: string
  #   exist: bool
  #   id : string
  #   body: string
  #   json
  #
  # proc initPage(path:string):Page =
  #   result.path:string = path
  #   result._json = result.get()

type Revision = object
  id: string
  body: string
  pageId: string

type Creator = object
  name: string
  username: string
  status: int

type Page = object
  id: string
  path: string
  revision: Revision
  creator: Creator

type Data = object
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

if is_main_module:
  let res = get(paramStr(1))
  # underscoreをobjectのfield名にできない仕様のせいで
  # stringを一部underscoreなしにする
  let jstr = res.body.multiReplace(
    ("\"_id\":", "\"id\":")
  )
  var data = to(parseJson(jstr), Data)
  echo data.page.revision.body
  echo data.page.revision.id
