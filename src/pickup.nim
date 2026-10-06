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

proc getTotalPageCount(): int =
  ## Growiの記事総数を読み込み
  ## レスポンスがJSONで受け取れなかったらエラーを吐く。
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

  return totalCount.parseInt()

proc responseToPageList(res: Response): PageList =
  ## Response 型をJSONパースしてPageListオブジェクトへ
  var jsn: JsonNode
  try:
    jsn = res.body.jsonReplace().parseJson()
  except JsonParsingError:
    echo "randomPickup JSON parse error", $JsonParsingError
    echo res.status, res.body
    return

  return jsn.to(PageList) # JSON -> Object 変換


proc randomPickup*(): PageList =
  ## Growiからランダムに記事JSONをcount個取得して
  ## PageList構造にパース
  ## pagesプロパティの値は配列だが、必ず1件だけのページ情報が含まれる
  ##
  ## Example:
  ## let pageList = randomPickup()
  ## echo pageList
  ## echo pretty(%pageList) # 整形JSON表示

  # 最大値がページ総数までのランダムな数字を取得
  let totalCount: int = getTotalPageCount()
  randomize() # seed初期化
  let offset = rand(totalCount)
  doAssert offset <= totalCount

  # ページ情報の取得
  const limit = 1 # 表示は1件に抑える。API側でlimitとpage の計算が走るらしい
  var pageRes: Response
  try:
    pageRes = getPages(path = "/", limit = limit, page = offset)
  except CatchableError as e:
    echo "Get response error", e.msg
    return

  # Response -> JSON -> PageList convert
  let pageList = responseToPageList(pageRes)
  return pageList

when isMainModule:
  let pageList = randomPickup()
  echo pretty(%pageList) # 整形JSON表示
