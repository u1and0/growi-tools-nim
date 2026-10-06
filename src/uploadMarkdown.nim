import std/httpclient

import helper
import growiapi
import pickup


when isMainModule:
  echo "=== ピックアップページコンテンツの作成 ==="
  let randomPage: PageElement = randomPickup().pages[0]
  let content: string = randomPage.extractArticleData().createPageBody()

  echo "アップロードされたページのレスポンス"
  const path = "/ピックアップ記事"
  let pickupPage: MetaPage = initMetaPage(path)
  let res = pickupPage.post(content)
  echo parseJsonSafe(res.body)
