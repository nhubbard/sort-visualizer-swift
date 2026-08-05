import kotlin.math.abs

// A ref is either a player leaf, encoded as -playerIndex (so ref <= 0), or another match
// node's root offset into matches (so ref > 0).
fun isPlayer(ref: Int): Boolean = ref <= 0

fun makePlayer(index: Int): Int = -index

fun getWinner(matches: IntArray, root: Int): Int = matches[root]

fun getWinners(matches: IntArray, root: Int): Int = matches[root + 1]

fun getLosers(matches: IntArray, root: Int): Int = matches[root + 2]

fun setMatch(matches: IntArray, root: Int, winner: Int, winners: Int, losers: Int) {
  matches[root] = winner
  matches[root + 1] = winners
  matches[root + 2] = losers
}

fun getPlayer(array: IntArray, matches: IntArray, ref: Int): Int =
  if (isPlayer(ref)) abs(ref) else getWinner(matches, ref)

fun makeMatch(array: IntArray, matches: IntArray, top: Int, bot: Int, root: Int): Int {
  val topWinner = getPlayer(array, matches, top)
  val botWinner = getPlayer(array, matches, bot)
  if (array[topWinner] <= array[botWinner]) {
    setMatch(matches, root, topWinner, top, bot)
  } else {
    setMatch(matches, root, botWinner, bot, top)
  }
  return root
}

fun knockout(array: IntArray, matches: IntArray, i: Int, k: Int, root: Int): Int {
  if (i == k) return makePlayer(i)
  val mid = (i + k) / 2
  val leftRef = knockout(array, matches, i, mid, 2 * root)
  val rightRef = knockout(array, matches, mid + 1, k, 2 * root + 3)
  return makeMatch(array, matches, leftRef, rightRef, root)
}

fun rebuild(array: IntArray, matches: IntArray, root: Int): Int {
  if (isPlayer(getWinners(matches, root))) {
    return getLosers(matches, root)
  }
  matches[root + 1] = rebuild(array, matches, getWinners(matches, root))
  if (array[getPlayer(array, matches, getLosers(matches, root))] <
    array[getPlayer(array, matches, getWinners(matches, root))]
  ) {
    matches[root] = getPlayer(array, matches, getLosers(matches, root))
    val previousLosers = getLosers(matches, root)
    matches[root + 2] = getWinners(matches, root)
    matches[root + 1] = previousLosers
  } else {
    matches[root] = getPlayer(array, matches, getWinners(matches, root))
  }
  return root
}

fun sort(array: IntArray) {
  val n = array.size
  if (n <= 1) return

  val matches = IntArray(6 * n)
  var tourney = knockout(array, matches, 0, n - 1, 3)

  val output = IntArray(n)
  for (i in 0 until n) {
    output[i] = array[getPlayer(array, matches, tourney)]
    tourney = if (isPlayer(tourney)) 0 else rebuild(array, matches, tourney)
  }
  output.copyInto(array)
}

fun main() {
  val array = intArrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println(array.joinToString(", ", "[", "]"))
}
