#[
Get Growi Page info

Uasge:
  growi /path/to/page
]#

import std/uri
import std/os
import std/httpclient
import std/json
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

let args = paramStr(1)
let res = get(args)
let js = parseJson(res.body)
let prt = js.pretty()
echo prt
# echo js["page"]["revision"]["body"]
var data = js.to(Data)
echo data.page.id
echo data.page.revision
echo data.page.revision.body
