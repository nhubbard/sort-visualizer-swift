/// Tags a value with its original index so a pending element can find its way back to the
/// right chain partner even after the chain has been recursively reordered.
struct Elem {
    let value: Int
    let index: Int
}

/// Inserts elem into the already-sorted seq via binary search, comparing by value only.
func binaryInsert(_ seq: inout [Elem], _ elem: Elem) {
    var lo = 0
    var hi = seq.count
    while lo < hi {
        let mid = (lo + hi) / 2
        if seq[mid].value <= elem.value {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    seq.insert(elem, at: lo)
}

/// Returns, as 1-based positions into a list of `count` not-yet-placed pending elements, the
/// order to insert them in: 2, then 4 and 3, then 10 down to 5, then 20 down to 11, and so on.
/// This Jacobsthal-number grouping is what makes merge-insertion sort comparison-optimal.
/// Position 1 is never included -- it is always placed for free before any of these insertions
/// happen.
func jacobsthalInsertionOrder(_ count: Int) -> [Int] {
    let maxPosition = count + 1
    var order: [Int] = []
    var placedThrough = 1
    var k = 2
    while placedThrough < maxPosition {
        let sign = (k % 2 == 0) ? 1 : -1
        let t = ((1 << (k + 1)) + sign) / 3
        let groupEnd = min(t - 1, maxPosition)
        var position = groupEnd
        while position > placedThrough {
            order.append(position)
            position -= 1
        }
        placedThrough = groupEnd
        k += 1
    }
    return order
}

/// Splits items into a (chain, partnerOf, extra) triple: chain holds the larger element of each
/// adjacent pair, partnerOf maps a chain element's original index to its paired (smaller)
/// element, and extra is a leftover element with no partner when items has odd length.
func pairUp(_ items: [Elem]) -> (chain: [Elem], partnerOf: [Int: Elem], extra: Elem?) {
    var chain: [Elem] = []
    var partnerOf: [Int: Elem] = [:]
    var i = 0
    let n = items.count
    while i + 1 < n {
        let a = items[i]
        let b = items[i + 1]
        let small = a.value <= b.value ? a : b
        let large = a.value <= b.value ? b : a
        partnerOf[large.index] = small
        chain.append(large)
        i += 2
    }
    let extra = i < n ? items[i] : nil
    return (chain, partnerOf, extra)
}

/// Sorts a list of Elem by value. The index tags are what let a pending element find its way
/// back to the right chain partner after the chain has been recursively reordered by this same
/// function one level down.
func sortTagged(_ items: [Elem]) -> [Elem] {
    if items.count <= 1 {
        return items
    }

    let (chain, partnerOf, extra) = pairUp(items)
    let sortedChain = sortTagged(chain)

    // The pending partner of the smallest chain element is guaranteed smaller than every other
    // chain element too, so it can go straight to the front with no comparison at all.
    var sequence = [partnerOf[sortedChain[0].index]!]
    sequence.append(contentsOf: sortedChain)

    var remaining: [Elem] = []
    for k in 1 ..< sortedChain.count {
        remaining.append(partnerOf[sortedChain[k].index]!)
    }
    if let extra {
        remaining.append(extra)
    }

    for position in jacobsthalInsertionOrder(remaining.count) {
        binaryInsert(&sequence, remaining[position - 2])
    }

    return sequence
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n < 2 {
        return
    }
    let tagged = arr.enumerated().map { Elem(value: $1, index: $0) }
    let sortedTagged = sortTagged(tagged)
    for i in 0 ..< n {
        arr[i] = sortedTagged[i].value
    }
}

var array: [Int] = [
    34, 7, 23, 90, 12, 56, 3, 45, 78, 21, 66, 9,
    50, 15, 88, 40, 61, 5, 33, 72, 18, 95, 27, 60,
]
sort(&array)
print(array)
