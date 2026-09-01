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
  std/sets,
  std/strformat,
  std/strutils,
  growiapi

proc randomPickup(count: int = 1): PageList =
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

  # 総数までのランダムな数字を取得
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
  let pagelist = randomPickup()
  echo pageList
  # echo pageList.totalCount
  echo pageList.pages[0].path


#[
let                                      # 掲載記事挿入文
  title = path.rsplit("/", 1)[1]         # タイトル(ページパス)
  page = initMetaPage(path).page
  creator = page.creator.username
  pageInfo = initClassicalPage(path)     # ページ情報取得
  body = page.revision.body              # サンプルページの本文
  revisions = initMetaRevisions(page.id) # 編集履歴
  authors: HashSet[Author.id] = toHashSet(revisions.authors())

# 掲載記事本文
let payload = &"""[[{title}>{path}]]

<span class="badge badge-primary">作成者: {creator}</span>
<span class="badge badge-pink">ライク数: {len(pageInfo.liker)}</span>
<span class="badge badge-orange">足跡数: {len(pageInfo.seenUsers)}</span>
<span class="badge badge-teal">編集者数: {len(authors)}</span>
<span class="badge badge-indigo">コメント数: {pageInfo.commentCount}</span>

{body}"""

# echo payload

# ページアップロード
let pickupPage = initMetaPage("/ピックアップ記事")
let res: Response = pickupPage.post(payload)
echo res.body.parseJson().pretty()
]#
