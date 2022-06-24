import std/uri
import std/os
import std/httpclient
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

echo get("/Wiki選定").body
