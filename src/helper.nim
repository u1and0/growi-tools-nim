import std/[json, httpclient, strutils]

proc jsonReplace*(body: string): string =
  ## jsonReplace(): jsonフィールドを任意に変更する
  ## underscoreをobjectのfield名にできない仕様のせいで
  ## stringを一部underscoreなしにする
  return body.multiReplace(
    ("\"_id\":", "\"id\":")
  )

proc parseJsonSafe*(res: Response) =
  try:
    let jsn = res.body.parseJson()
    echo jsn.pretty()
  except JsonParsingError:
    echo res.body

