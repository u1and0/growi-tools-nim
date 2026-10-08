## Growi記事ランキングの集計・整形 (API非依存)
import std/[strformat, algorithm, sequtils]

type
  Rank* = object
    path*, id*: string
    liker*, seen*, commentCount*, authors*: int

  Ranks* = seq[Rank]

  RankKey* = enum
    rkLiker, rkSeen, rkCommentCount, rkAuthors

proc value(r: Rank, k: RankKey): int =
  case k
  of rkLiker: r.liker
  of rkSeen: r.seen
  of rkCommentCount: r.commentCount
  of rkAuthors: r.authors

proc sortBy*(ranks: var Ranks, k: RankKey) =
  ranks.sort(proc(a, b: Rank): int = cmp(a.value(k), b.value(k)), Descending)

proc convert*(ranks: Ranks, origin: string): seq[string] =
  ranks.mapIt(&"[{it.path}]({origin}/{it.id}) :heart:{it.liker} " &
              &":footprints:{it.seen} :speech_balloon:{it.commentCount} " &
              &":pencil2:{it.authors}")

proc shift*(before, after: seq[string]): seq[string] =
  ## beforeの各idについてafter内の位置と比較し、上/下/横/newの記号を返す
  let beforeRanks = before.mapIt(after.find(it))       # 未登場は -1
  for afterRank, beforeRank in beforeRanks:
    result.add:
      if beforeRank < 0: ":new:"
      elif beforeRank - afterRank > 0: ":arrow_upper_right:"
      elif beforeRank - afterRank < 0: ":arrow_lower_right:"
      else: ":arrow_right:"

proc order*(ranks: Ranks, top: int, ids: seq[string],
            origin: string): seq[string] =
  let topRanks = ranks[0 ..< min(top, ranks.len)]
  let afterRanks = topRanks.convert(origin)
  let arrows =
    if ids.len > 0: shift(ids, topRanks.mapIt(it.id))
    else: newSeq[string](top) # 初回: 矢印なし
  for i in 0 ..< min(arrows.len, afterRanks.len):
    result.add &"{i + 1}. {arrows[i]} {afterRanks[i]}"

proc readIds*(paragraph: string): seq[string] =
  ## 24桁の[a-f0-9]を抽出 (re.findall(r"[a-f0-9]{24}") 相当)
  proc isHex(ch: char): bool = ch in {'0'..'9', 'a'..'f'}
  var i = 0
  while i + 24 <= paragraph.len:
    if paragraph[i ..< i + 24].allIt(it.isHex):
      result.add paragraph[i ..< i + 24]
      i += 24
    else:
      inc i
