// Tags a value with its original index so a pending element can find its way back to the
// right chain partner even after the chain has been recursively reordered.
data class Elem(
  val value: Int,
  val index: Int,
)

// Inserts elem into the already-sorted seq via binary search, comparing by value only.
fun binaryInsert(seq: MutableList<Elem>, elem: Elem) {
  var lo = 0
  var hi = seq.size
  while (lo < hi) {
    val mid = (lo + hi) / 2
    if (seq[mid].value <= elem.value) {
      lo = mid + 1
    } else {
      hi = mid
    }
  }
  seq.add(lo, elem)
}

// Returns, as 1-based positions into a list of `count` not-yet-placed pending elements, the
// order to insert them in: 2, then 4 and 3, then 10 down to 5, then 20 down to 11, and so on.
// This Jacobsthal-number grouping is what makes merge-insertion sort comparison-optimal.
// Position 1 is never included -- it is always placed for free before any of these insertions
// happen.
fun jacobsthalInsertionOrder(count: Int): List<Int> {
  val maxPosition = count + 1
  val order = mutableListOf<Int>()
  var placedThrough = 1
  var k = 2
  while (placedThrough < maxPosition) {
    val sign = if (k % 2 == 0) 1 else -1
    val t = ((1 shl (k + 1)) + sign) / 3
    val groupEnd = minOf(t - 1, maxPosition)
    for (position in groupEnd downTo placedThrough + 1) {
      order.add(position)
    }
    placedThrough = groupEnd
    k++
  }
  return order
}

// Splits items into a (chain, partnerOf, extra) triple: chain holds the larger element of each
// adjacent pair, partnerOf maps a chain element's original index to its paired (smaller)
// element, and extra is a leftover element with no partner when items has odd length.
fun pairUp(items: List<Elem>): Triple<List<Elem>, Map<Int, Elem>, Elem?> {
  val chain = mutableListOf<Elem>()
  val partnerOf = mutableMapOf<Int, Elem>()
  var i = 0
  val n = items.size
  while (i + 1 < n) {
    val a = items[i]
    val b = items[i + 1]
    val small = if (a.value <= b.value) a else b
    val large = if (a.value <= b.value) b else a
    partnerOf[large.index] = small
    chain.add(large)
    i += 2
  }
  val extra = if (i < n) items[i] else null
  return Triple(chain, partnerOf, extra)
}

// Sorts a list of Elem by value. The index tags are what let a pending element find its way
// back to the right chain partner after the chain has been recursively reordered by this same
// function one level down.
fun sortTagged(items: List<Elem>): List<Elem> {
  if (items.size <= 1) {
    return items.toList()
  }

  val (chain, partnerOf, extra) = pairUp(items)
  val sortedChain = sortTagged(chain)

  // The pending partner of the smallest chain element is guaranteed smaller than every other
  // chain element too, so it can go straight to the front with no comparison at all.
  val sequence = mutableListOf(partnerOf[sortedChain[0].index]!!)
  sequence.addAll(sortedChain)

  val remaining = mutableListOf<Elem>()
  for (k in 1 until sortedChain.size) {
    remaining.add(partnerOf[sortedChain[k].index]!!)
  }
  if (extra != null) {
    remaining.add(extra)
  }

  for (position in jacobsthalInsertionOrder(remaining.size)) {
    binaryInsert(sequence, remaining[position - 2])
  }

  return sequence
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) return
  val tagged = arr.mapIndexed { index, value -> Elem(value, index) }
  val sortedTagged = sortTagged(tagged)
  for (i in 0 until n) {
    arr[i] = sortedTagged[i].value
  }
}

fun main() {
  var array = arrayOf<Int>(
    34, 7, 23, 90, 12, 56, 3, 45, 78, 21, 66, 9,
    50, 15, 88, 40, 61, 5, 33, 72, 18, 95, 27, 60,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
