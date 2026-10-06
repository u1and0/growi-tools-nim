#[
# Growi ピックアップ記事を抽出するモジュール
# 全ページの中からランダムに1つのパスを選定し、下記を表示します。
#   * タイトル( ページパス )
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
  std/strformat,
  std/sets,

  helper,
  growiapi


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
  return responseToPageList(pageRes)

type ArticleData* = object
  ## 掲載記事のまとめデータ構造
  title*: string       ## Growiページのパスの/で区切られたパスの一番右
  path*: string        ## Growiのページパス
  creatorName*: string ## 作成者
  body*: string        ## ページ内容
  commentCount*: int
  # page element の情報を加工して得られるデータ
  likerNum*: int
  seenUsersNum*: int
  # revision の情報を加工して得られるデータ
  authorsNum*: int

  # revisions*: MetaRevisions

func getTitle(path: string): string =
  path.rsplit("/", 1)[1]

proc extractArticleData*(pageElem: PageElement): ArticleData =
  ## 記事情報の取得とオブジェクト生成
  let
    # パスとタイトルの基本情報を取得
    path = pageElem.path
    title = getTitle(path)

    # 作成者と内容
    metaPage = initMetaPage(path)
    page = metaPage.page

    # 編集者数の算出
    revisions = initMetaRevisions(pageElem.id)
    authors: HashSet[string] = revisions.authors()

  result = ArticleData(
    title: title,
    path: path,
    creatorName: page.creator.name,
    body: page.revision.body,
    commentCount: pageElem.commentCount,
    likerNum: len(pageElem.liker),
    seenUsersNum: len(pageElem.seenUsers),
    authorsNum: len(authors)
  )

func createPageBody*(a: ArticleData): string =
  ## 掲載記事本文の文字列を作成する
  fmt"""[[{a.title}>{a.path}]]

  <span class="badge badge-primary">作成者: {a.creatorName}</span>
  <span class="badge badge-danger">ライク数: {a.likerNum}</span>
  <span class="badge badge-warning">足跡数: {a.seenUsersNum}</span>
  <span class="badge badge-info">編集者数: {a.authorsNum}</span>
  <span class="badge badge-success">コメント数: {a.commentCount}</span>

  {a.body}"""

when isMainModule:
  # echo "=== ランダムに選んだページの内容==="
  let pageList = randomPickup()
  # echo pretty(%pageList) # 整形JSON表示

  # echo "=== ピックアップページコンテンツの作成 ==="
  let randomPage: PageElement = pageList.pages[0]
  let article = extractArticleData(randomPage)
  # echo article.createPageBody()
  let content: string = article.createPageBody()

  echo "=== アップロードされたページのレスポンス ==="
  const path = "/ピックアップ記事"
  let pickupPage: MetaPage = initMetaPage(path)
  let res = pickupPage.post(content)
  echo parseJsonSafe(res.body)
