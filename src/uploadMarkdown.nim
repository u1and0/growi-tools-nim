import
  std/sets,
  std/strutils,
  std/json,
  growiapi,
  pickup

## 掲載記事のまとめデータ構造
type ArticleData* = object
  title*: string
  path*: string
  page*: Page
  creator*: Creator
  pageInfo*: MetaPage
  body*: string
  # revisions*: MetaRevisions
  # authors*: HashSet[string]


proc extractArticleData*(path: string): ArticleData =
  ## 記事情報の取得とオブジェクト生成
  let
    title = path.rsplit("/", 1)[1]
    metaPage = initMetaPage(path)
    page = metaPage.page
    creator = page.creator
    pageInfo = initMetaPage(path)
    body = page.revision.body
    # revisions = initMetaRevisions(page.id)
    # authors: HashSet[string] = toHashSet(revisions.authors())

  result = ArticleData(
    title: title,
    path: path,
    page: page,
    creator: creator,
    pageInfo: pageInfo,
    body: body,
    # revisions: revisions,
      # authors: authors
  )

# func createPageBody(path: string): string =
#   ## 掲載記事本文の文字列を作成する
#   let a = extractArticleData(path)
#   return &"""[[{a.title}>{a.path}]]
#
#   <span class="badge badge-primary">作成者: {a.page.creator.name}</span>
#   <span class="badge badge-pink">ライク数: {len(a.pageInfo.liker)}</span>
#   <span class="badge badge-orange">足跡数: {len(a.pageInfo.seenUsers)}</span>
#   <span class="badge badge-teal">編集者数: {len(a.authors)}</span>
#   <span class="badge badge-indigo">コメント数: {a.pageInfo.commentCount}</span>
#
#   {a.page.body}"""

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

  let article = extractArticleData(page.path)
  echo %article

#[
  page = initMetaPage(path).page

  creator = page.creator.username
  pageInfo = initClassicalPage(path) # ページ情報取得
  body = page.revision.body # サンプルページの本文
  revisions = initMetaRevisions(page.id) # 編集履歴
  authors: HashSet[Author.id] = toHashSet(revisions.authors())


  # echo payload
]#
