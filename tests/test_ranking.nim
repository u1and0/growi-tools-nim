## ranks.nim test
## run: nim c -r -d:ssl test_ranking.nim
import std/[unittest, strutils]

import ranks

const origin = "https://demo.growi.org"

suite "Ranks.shift":
  test "ランク内で順位が変わるケース":
    let be = "a b c".split()
    let af = "c b a".split()
    check shift(be, af) ==
      @[":arrow_upper_right:", ":arrow_right:", ":arrow_lower_right:"]

  test "ランク外から上がってきたケース":
    let be = "a b c d".split()
    let af = "c b a e".split()
    check shift(be, af) ==
      @[":arrow_upper_right:", ":arrow_right:", ":arrow_lower_right:", ":new:"]

  test "ランク外から２位に上がってきたケース":
    let be = "a b c d".split()
    let af = "c e a d".split()
    check shift(be, af) ==
      @[":arrow_upper_right:", ":new:", ":arrow_lower_right:", ":arrow_right:"]

suite "Ranks.order":
  test "順位変動のみ":
    var ranks: Ranks = @[
      Rank(path: "/rank1", id: "1111", liker: 0),
      Rank(path: "/rank2", id: "2222", liker: 1),
      Rank(path: "/rank3", id: "3333", liker: 2),
    ]
    let ids = @["1111", "2222", "3333"]
    ranks.sortBy(rkLiker)
    let expected = @[
      "1. :arrow_upper_right: [/rank3](https://demo.growi.org/3333) " &
        ":heart:2 :footprints:0 :speech_balloon:0 :pencil2:0",
      "2. :arrow_right: [/rank2](https://demo.growi.org/2222) " &
        ":heart:1 :footprints:0 :speech_balloon:0 :pencil2:0",
      "3. :arrow_lower_right: [/rank1](https://demo.growi.org/1111) " &
        ":heart:0 :footprints:0 :speech_balloon:0 :pencil2:0",
    ]
    check ranks.order(3, ids, origin) == expected

  test "ランク外から新規ランクイン":
    var ranks: Ranks = @[
      Rank(path: "/rank1", id: "1111", liker: 0),
      Rank(path: "/rank2", id: "2222", liker: 1),
      Rank(path: "/rank3", id: "3333", liker: 2),
      Rank(path: "/rank4", id: "4444", liker: 10),
    ]
    let ids = @["1111", "2222", "3333"]
    ranks.sortBy(rkLiker)
    let expected = @[
      "1. :new: [/rank4](https://demo.growi.org/4444) " &
        ":heart:10 :footprints:0 :speech_balloon:0 :pencil2:0",
      "2. :arrow_upper_right: [/rank3](https://demo.growi.org/3333) " &
        ":heart:2 :footprints:0 :speech_balloon:0 :pencil2:0",
      "3. :arrow_lower_right: [/rank2](https://demo.growi.org/2222) " &
        ":heart:1 :footprints:0 :speech_balloon:0 :pencil2:0",
    ]
    check ranks.order(3, ids, origin) == expected
