import
  std/strformat,
  std/sets,
  std/strutils,
  std/json,
  growiapi,
  pickup

## 掲載記事のまとめデータ構造
type ArticleData* = object
  title*: string
  path*: string
  creatorName*: string
  body*: string
  commentCount*: int
  # page element の情報を加工して得られる数値
  likerNum: int
  seenUsersNum: int

  # revisions*: MetaRevisions
  # authors*: HashSet[string]


proc extractArticleData*(pageElem: PageElement): ArticleData =
  ## 記事情報の取得とオブジェクト生成
  let
    path = pageElem.path
    title = path.rsplit("/", 1)[1]
    metaPage = initMetaPage(path)
    page = metaPage.page
    # revisions = initMetaRevisions(page.id)
    # authors: HashSet[string] = toHashSet(revisions.authors())

  result = ArticleData(
    title: title,
    path: path,
    creatorName: page.creator.name,
    body: page.revision.body,
    commentCount: pageElem.commentCount,
    likerNum: len(pageElem.liker),
    seenUsersNum: len(pageElem.seenUsers),
    # revisions: revisions,
      # authors: authors
  )

func createPageBody(a: ArticleData): string =
  ## 掲載記事本文の文字列を作成する
  fmt"""[[{a.title}>{a.path}]]

  <span class="badge badge-primary">作成者: {a.creatorName}</span>
  <span class="badge badge-pink">ライク数: {a.likerNum}</span>
  <span class="badge badge-orange">足跡数: {a.seenUsersNum}</span>
  <span class="badge badge-teal">編集者数: 保留</span>
  <span class="badge badge-indigo">コメント数: {a.commentCount}</span>

  {a.body}"""
  # <span class="badge badge-teal">編集者数: {len(a.authors)}</span>

# proc uploadPickupArticle(page: Page): Response =
#   ## "/ピックアップ記事"ページに記事内容を投稿する
#   let body = createPageBody(page)
#   let pickupPage = initMetaPage("/ピックアップ記事")
#   return pickupPage.post(body)
#   # echo res.body.parseJson().pretty()
#   # return res.body.parseJson()

when isMainModule:
  let
    pageList: PageList = randomPickup()
    page: PageElement = pageList.pages[0]
    meta: MetaPage = initMetaPage(page.path)
  # echo pretty(%meta)

  let article = extractArticleData(page)
  echo article.createPageBody()

#[
  page = initMetaPage(path).page

  creator = page.creator.username
  pageInfo = initClassicalPage(path) # ページ情報取得
  body = page.revision.body # サンプルページの本文
  revisions = initMetaRevisions(page.id) # 編集履歴
  authors: HashSet[Author.id] = toHashSet(revisions.authors())


  # echo payload
]#
