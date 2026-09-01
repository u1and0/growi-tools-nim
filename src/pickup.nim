#[
# pages.list がdeprecated になったようだ。使えない。
# 相当するAPIも見つからない
#
# Growi ピックアップ記事を抽出するモジュール
# 全ページの中からランダムに1つのパスを選定し、下記を表示します。
#   * タイトル( ページパス )
#   //* 最近の編集者
#   * 作成者
#   * ライク数
#   * 足跡数
#   * 編集者数
#   * コメント数
#   * 本文
]#
import
  std/httpclient,
  std/json,
  std/random,
  std/strutils,
  growiapi

proc randomPickup*(count: int = 1): PageList =
  ## Growiからランダムに記事JSONをcount個取得して
  ## PageList構造にパース

  # Growiの記事総数を読み込み
  var res: Response
  try:
    res = getPages()
  except CatchableError as e:
    echo "Get response error", e.msg
    return

  var totalCount: string
  try:
    totalCount = $res.body.parseJson()["totalCount"]
  except JsonParsingError:
    echo res.status, res.body
    return

  # 最大値がページ総数までのランダムな数字を取得
  randomize() # seed初期化
  let randInt: int = parseInt($totalCount).rand()

  # ページ情報の取得
  var pageRes: Response
  try:
    pageRes = getPages(path = "/", limit = count, page = randInt)
  except CatchableError as e:
    echo "Get response error", e.msg
    return

  var jsn: JsonNode
  try:
    let jsnReplaced = jsonReplace(pageRes.body)
    jsn = jsnReplaced.parseJson()
  except JsonParsingError:
    echo res.status, res.body
    return

  return jsn.to(PageList)

when isMainModule:
  let pageList = randomPickup()
  echo pretty(%pageList) # 整形JSON表示
