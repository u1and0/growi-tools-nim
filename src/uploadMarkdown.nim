import
  std/[strformat, strutils, sets],
  growiapi,
  pickup

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


proc extractArticleData*(pageElem: PageElement): ArticleData =
  ## 記事情報の取得とオブジェクト生成
  let
    path = pageElem.path
    title = path.rsplit("/", 1)[1]
    metaPage = initMetaPage(path)
    page = metaPage.page
    revisions = initMetaRevisions(page.id)
    authors: HashSet[string] = revisions.authors()

  echo pageElem

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

func createPageBody(a: ArticleData): string =
  ## 掲載記事本文の文字列を作成する
  fmt"""[[{a.title}>{a.path}]]

  <span class="badge badge-primary">作成者: {a.creatorName}</span>
  <span class="badge badge-pink">ライク数: {a.likerNum}</span>
  <span class="badge badge-orange">足跡数: {a.seenUsersNum}</span>
  <span class="badge badge-teal">編集者数: {a.authorsNum}</span>
  <span class="badge badge-indigo">コメント数: {a.commentCount}</span>

  {a.body}"""
  # <span class="badge badge-teal">編集者数: {len(a.authors)}</span>

# proc uploadPickupArticle(body: string): Response =
#   ## "/ピックアップ記事"ページに記事内容を投稿する
#   let pickupPage = initMetaPage("/ピックアップ記事")
#   return pickupPage.post(body)

when isMainModule:
  let
    pageList: PageList = randomPickup()
    page: PageElement = pageList.pages[0]

  let article = extractArticleData(page)
  echo article.createPageBody()

  # let revisions = initMetaRevisions(page.id)
  # echo %revisions
  # let res = uploadPickupArticle(content)
  # echo res.body.parseJson().pretty()
  # return res.body.parseJson()
