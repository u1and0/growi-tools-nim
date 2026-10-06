import std/[json, os, strutils]

proc jsonReplace*(body: string): string =
  ## jsonReplace(): jsonフィールドを任意に変更する
  ## underscoreをobjectのfield名にできない仕様のせいで
  ## stringを一部underscoreなしにする
  return body.multiReplace(
    ("\"_id\":", "\"id\":")
  )

proc parseJsonSafe*(body: string): string =
  ## response.body をJSONパースして整形表示
  ## パースに失敗したらbodyをそのまま表示
  try:
    let jsn = body.parseJson()
    jsn.pretty()
  except JsonParsingError:
    body

proc readFilePath*(path: string): string =
  ## pathがファイルパスとして存在していれば、
  ## ファイルの内容を返す。
  ## そうでなければ文字列そのままを返す
  if fileExists(path):
    return readFile(path)
  return path
