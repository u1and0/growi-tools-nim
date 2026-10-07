## Growi URL, トークンを環境変数から読込み、
## HTTPクライアントを生成します。
import std/[os, httpclient, uri]

## https://demo.growi.org/
let URI* = getEnv("GROWI_URL", "http://localhost:3000").parseUri()

## Get token from https://demo.growi.org/me
let TOKEN* = getEnv("GROWI_ACCESS_TOKEN")
if TOKEN == "":
  var e: ref KeyError
  new(e)
  e.msg = "アクセストークンが設定されていません"
  raise e

let headers = newHttpHeaders({"Content-Type": "application/json"})
let CLIENT* = newHttpClient(headers = headers)
