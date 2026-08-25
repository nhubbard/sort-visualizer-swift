# Inserts elem into the already-sorted seq via binary search, comparing by value only.
def binary_insert(seq, elem)
  lo = 0
  hi = seq.length
  value = elem[0]
  while lo < hi
    mid = (lo + hi) / 2
    if seq[mid][0] <= value
      lo = mid + 1
    else
      hi = mid
    end
  end
  seq.insert(lo, elem)
end

# Returns, as 1-based positions into a list of `count` not-yet-placed pending elements, the
# order to insert them in: 2, then 4 and 3, then 10 down to 5, then 20 down to 11, and so on.
# This Jacobsthal-number grouping is what makes merge-insertion sort comparison-optimal.
# Position 1 is never included -- it is always placed for free before any of these insertions
# happen.
def jacobsthal_insertion_order(count)
  max_position = count + 1
  order = []
  placed_through = 1
  k = 2
  while placed_through < max_position
    sign = k.even? ? 1 : -1
    group_end = [((2**(k + 1) + sign) / 3) - 1, max_position].min
    group_end.downto(placed_through + 1) { |position| order << position }
    placed_through = group_end
    k += 1
  end
  order
end

# Splits items into [chain, partner_of, extra]: chain holds the larger element of each adjacent
# pair, partner_of maps a chain element's original index to its paired (smaller) element, and
# extra is a leftover element with no partner when items has odd length. Every element keeps its
# original index tagged alongside its value so a later step can find the right partner even when
# values repeat.
def pair_up(items)
  chain = []
  partner_of = {}
  i = 0
  n = items.length
  while i + 1 < n
    a = items[i]
    b = items[i + 1]
    small, large = (a[0] <= b[0]) ? [a, b] : [b, a]
    partner_of[large[1]] = small
    chain << large
    i += 2
  end
  extra = (i < n) ? items[i] : nil
  [chain, partner_of, extra]
end

# Sorts a list of [value, original_index] pairs by value. The index tags are what let a pending
# element find its way back to the right chain partner after the chain has been recursively
# reordered by this same function one level down.
def sort_tagged(items)
  return items.dup if items.length <= 1

  chain, partner_of, extra = pair_up(items)
  sorted_chain = sort_tagged(chain)

  # The pending partner of the smallest chain element is guaranteed smaller than every other
  # chain element too, so it can go straight to the front with no comparison at all.
  sequence = [partner_of[sorted_chain[0][1]]] + sorted_chain

  remaining = (1...sorted_chain.length).map { |k| partner_of[sorted_chain[k][1]] }
  remaining << extra unless extra.nil?

  jacobsthal_insertion_order(remaining.length).each do |position|
    binary_insert(sequence, remaining[position - 2])
  end

  sequence
end

def sort(arr)
  n = arr.length
  return if n < 2

  tagged = arr.each_with_index.map { |value, index| [value, index] }
  sorted_tagged = sort_tagged(tagged)
  sorted_tagged.each_with_index { |(value, _index), i| arr[i] = value }
end

array = [34, 7, 23, 90, 12, 56, 3, 45, 78, 21, 66, 9, 50, 15, 88, 40, 61, 5, 33, 72, 18, 95, 27, 60]
sort(array)
p array
