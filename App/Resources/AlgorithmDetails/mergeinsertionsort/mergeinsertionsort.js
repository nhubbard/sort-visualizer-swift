// Inserts elem into the already-sorted seq via binary search, comparing by value only.
function binaryInsert(seq, elem) {
  let lo = 0;
  let hi = seq.length;
  const value = elem[0];
  while (lo < hi) {
    const mid = Math.floor((lo + hi) / 2);
    if (seq[mid][0] <= value) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  seq.splice(lo, 0, elem);
}

// Returns, as 1-based positions into a list of `count` not-yet-placed pending elements, the
// order to insert them in: 2, then 4 and 3, then 10 down to 5, then 20 down to 11, and so on.
// This Jacobsthal-number grouping is what makes merge-insertion sort comparison-optimal.
// Position 1 is never included -- it is always placed for free before any of these insertions
// happen.
function jacobsthalInsertionOrder(count) {
  const maxPosition = count + 1;
  const order = [];
  let placedThrough = 1;
  let k = 2;
  while (placedThrough < maxPosition) {
    const sign = k % 2 === 0 ? 1 : -1;
    const groupEnd = Math.min((2 ** (k + 1) + sign) / 3 - 1, maxPosition);
    for (let position = groupEnd; position > placedThrough; position--) {
      order.push(position);
    }
    placedThrough = groupEnd;
    k++;
  }
  return order;
}

// Splits items into (chain, partnerOf, extra): chain holds the larger element of each adjacent
// pair, partnerOf maps a chain element's original index to its paired (smaller) element, and
// extra is a leftover element with no partner when items has odd length. Every element keeps
// its original index tagged alongside its value so a later step can find the right partner even
// when values repeat.
function pairUp(items) {
  const chain = [];
  const partnerOf = new Map();
  let i = 0;
  const n = items.length;
  while (i + 1 < n) {
    const a = items[i];
    const b = items[i + 1];
    const [small, large] = a[0] <= b[0] ? [a, b] : [b, a];
    partnerOf.set(large[1], small);
    chain.push(large);
    i += 2;
  }
  const extra = i < n ? items[i] : null;
  return [chain, partnerOf, extra];
}

// Sorts a list of [value, originalIndex] pairs by value. The index tags are what let a pending
// element find its way back to the right chain partner after the chain has been recursively
// reordered by this same function one level down.
function sortTagged(items) {
  if (items.length <= 1) {
    return items.slice();
  }

  const [chain, partnerOf, extra] = pairUp(items);
  const sortedChain = sortTagged(chain);

  // The pending partner of the smallest chain element is guaranteed smaller than every other
  // chain element too, so it can go straight to the front with no comparison at all.
  const sequence = [partnerOf.get(sortedChain[0][1]), ...sortedChain];

  const remaining = [];
  for (let k = 1; k < sortedChain.length; k++) {
    remaining.push(partnerOf.get(sortedChain[k][1]));
  }
  if (extra !== null) {
    remaining.push(extra);
  }

  for (const position of jacobsthalInsertionOrder(remaining.length)) {
    binaryInsert(sequence, remaining[position - 2]);
  }

  return sequence;
}

function sort(arr) {
  const n = arr.length;
  if (n < 2) return;
  const tagged = arr.map((value, index) => [value, index]);
  const sortedTagged = sortTagged(tagged);
  for (let i = 0; i < n; i++) {
    arr[i] = sortedTagged[i][0];
  }
}

var array = [
  34, 7, 23, 90, 12, 56, 3, 45, 78, 21, 66, 9, 50, 15, 88, 40, 61, 5, 33, 72,
  18, 95, 27, 60,
];
sort(array);
console.log("[" + array.join(", ") + "]");
