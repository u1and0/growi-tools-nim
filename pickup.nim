#[
# Growi ピックアップ記事を抽出するモジュール
# ルート上からランダムに1つのパスを選定し、下記を表示します。
#   * タイトル( ページパス )
#   * 最近の編集者
#   * 作成者
#   * ライク数
#   * コメント数
#   * 足跡数
#   * コメント数
#   * 本文
]#
import std/httpclient
import std/json
import std/random
import std/strformat
import std/strutils
import growiapi

# ランダムにピックアップ
let root = initMetaPage("/", limit = 10000)
let pageList = root.tree()
randomize()

# タイトル(ページパス)
let path = sample(pageList)
let title = path.rsplit("/", 1)[1]

# ページ情報取得
let metaPage = initMetaPage(path)
let page = metaPage.page

# let pages = metapage.tree()
# echo "作成者: " & page.creator.username
let creator: string = page.creator.username
  # echo "ライク数: " & $rev0.liker


# 本文
let body = page.revision.body

let payload = &"""[[{title}>{path}]]

<span class="badge badge-primary">作成者: {creator}</span>
<span class="badge badge-pink">ライク数: 000</span>
<span class="badge badge-orange">足跡数: 000</span>
<span class="badge badge-teal">編集者数: 000</span>
<span class="badge badge-indigo">コメント数数: 000</span>

{body}"""

# echo payload

# ページアップロード
let pickupPage = initMetaPage("/ピックアップ記事")
let res: Response = pickupPage.post(payload)
echo res.body.parseJson().pretty()
