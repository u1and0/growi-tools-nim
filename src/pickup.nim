#[
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

# ランダムにピックアップ
randomize()
let
  pageList = initMetaPage("/", limit = 10000).tree()
  path = sample(pageList)

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
