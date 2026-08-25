def binary_insert(seq, elem):
    # Inserts elem into the already-sorted seq via binary search, comparing by value only.
    lo, hi = 0, len(seq)
    value = elem[0]
    while lo < hi:
        mid = (lo + hi) // 2
        if seq[mid][0] <= value:
            lo = mid + 1
        else:
            hi = mid
    seq.insert(lo, elem)


def jacobsthal_insertion_order(count):
    # Returns, as 1-based positions into a list of `count` not-yet-placed pending elements,
    # the order to insert them in: 2, then 4 and 3, then 10 down to 5, then 20 down to 11, and
    # so on. This Jacobsthal-number grouping is what makes merge-insertion sort
    # comparison-optimal. Position 1 is never included -- it is always placed for free before
    # any of these insertions happen.
    max_position = count + 1
    order = []
    placed_through = 1
    k = 2
    while placed_through < max_position:
        group_end = min((2 ** (k + 1) + (-1) ** k) // 3 - 1, max_position)
        order.extend(range(group_end, placed_through, -1))
        placed_through = group_end
        k += 1
    return order


def pair_up(items):
    # Splits items into (chain, partner_of, extra): chain holds the larger element of each
    # adjacent pair, partner_of maps a chain element's original index to its paired (smaller)
    # element, and extra is a leftover element with no partner when items has odd length.
    # Every element keeps its original index tagged alongside its value so a later step can
    # find the right partner even when values repeat.
    chain = []
    partner_of = {}
    i = 0
    n = len(items)
    while i + 1 < n:
        a, b = items[i], items[i + 1]
        small, large = (a, b) if a[0] <= b[0] else (b, a)
        partner_of[large[1]] = small
        chain.append(large)
        i += 2
    extra = items[i] if i < n else None
    return chain, partner_of, extra


def sort_tagged(items):
    # Sorts a list of (value, original_index) tuples by value. The index tags are what let a
    # pending element find its way back to the right chain partner after the chain has been
    # recursively reordered by this same function one level down.
    if len(items) <= 1:
        return list(items)

    chain, partner_of, extra = pair_up(items)
    sorted_chain = sort_tagged(chain)

    # The pending partner of the smallest chain element is guaranteed smaller than every other
    # chain element too, so it can go straight to the front with no comparison at all.
    sequence = [partner_of[sorted_chain[0][1]]] + sorted_chain

    remaining = [partner_of[sorted_chain[k][1]] for k in range(1, len(sorted_chain))]
    if extra is not None:
        remaining.append(extra)

    for position in jacobsthal_insertion_order(len(remaining)):
        binary_insert(sequence, remaining[position - 2])

    return sequence


def sort(arr):
    n = len(arr)
    if n < 2:
        return
    tagged = [(value, index) for index, value in enumerate(arr)]
    sorted_tagged = sort_tagged(tagged)
    for i, (value, _index) in enumerate(sorted_tagged):
        arr[i] = value


if __name__ == "__main__":
    array = [
        34,
        7,
        23,
        90,
        12,
        56,
        3,
        45,
        78,
        21,
        66,
        9,
        50,
        15,
        88,
        40,
        61,
        5,
        33,
        72,
        18,
        95,
        27,
        60,
    ]
    sort(array)
    print(array)
