const INSERTION_THRESHOLD = 24;

function binaryInsertionSort(arr, start, end) {
  // Sorts arr[start..end) in place using a plain binary-search insertion sort -- the base case
  // once a segment shrinks small enough that further partitioning isn't worth it.
  for (let i = start; i < end; i++) {
    const value = arr[i];
    let lo = start;
    let hi = i;
    while (lo < hi) {
      const mid = lo + Math.floor((hi - lo) / 2);
      if (value < arr[mid]) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    let j = i - 1;
    while (j >= lo) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[lo] = value;
  }
}

function lowerBoundIndex(arr, start, end, targetIndex) {
  // Finds where the value at targetIndex belongs among arr[start..end), ties resolving toward
  // the front (a plain lower-bound binary search).
  let lo = start;
  let hi = end;
  while (lo < hi) {
    const mid = lo + Math.floor((hi - lo) / 2);
    if (arr[targetIndex] <= arr[mid]) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

function partition(arr, start, endIn, scratch) {
  // Dual-pivot partition of arr[start..end). `scratch` is a fixed index outside this range,
  // borrowed briefly as scratch space by the closing rotation and immediately restored. Returns
  // the boundary between the low region and everything at or above the smaller of the two
  // pivots.
  let end = endIn;
  const m1 = Math.floor((start + start + end) / 3);
  const m2 = Math.floor((start + end + end) / 3);

  if (arr[m1] > arr[m2]) {
    [arr[m1], arr[start]] = [arr[start], arr[m1]];
    end--;
    [arr[m2], arr[end]] = [arr[end], arr[m2]];
  } else {
    [arr[m2], arr[start]] = [arr[start], arr[m2]];
    end--;
    [arr[m1], arr[end]] = [arr[end], arr[m1]];
  }

  let low = start;
  let high = end;
  // Reversed from the usual low/high naming: after the swaps above, `start` holds the larger of
  // the two chosen medians and `end` the smaller. Neither position moves again until the
  // closing rotation below, so their values are safe to hold onto directly.
  const pivotMax = arr[start];
  const pivotMin = arr[end];

  let k = low + 1;
  while (k < high) {
    if (arr[k] < pivotMin) {
      low++;
      [arr[k], arr[low]] = [arr[low], arr[k]];
    } else if (arr[k] >= pivotMax) {
      do {
        high--;
      } while (high > k && arr[high] >= pivotMax);
      [arr[k], arr[high]] = [arr[high], arr[k]];
      if (arr[k] < pivotMin) {
        low++;
        [arr[k], arr[low]] = [arr[low], arr[k]];
      }
    }
    k++;
  }

  [arr[start], arr[low]] = [arr[low], arr[start]];
  // Three-way rotation: the value at `end` moves to `scratch`, whatever was borrowed from
  // `scratch` moves to `high`, and whatever was at `high` moves to `end`.
  const displaced = arr[end];
  arr[end] = arr[high];
  arr[high] = arr[scratch];
  arr[scratch] = displaced;

  return low;
}

function quickSort(arr, start, endIn) {
  // Sorts arr[start..end) in place with no recursion: a single loop processes one segment at a
  // time, shrinking and partitioning it down to INSERTION_THRESHOLD elements, finishing with
  // binaryInsertionSort, then advancing past it to the next segment.
  let end = endIn;

  // Move every copy of this range's maximum value to the very end first. Those elements are
  // already correctly placed relative to everything else, so the rest of the algorithm never
  // has to look at them again -- and the boundary in front of them becomes fixed scratch space
  // partition can borrow from.
  let maxValue = arr[start];
  for (let i = start + 1; i < end; i++) {
    if (arr[i] > maxValue) maxValue = arr[i];
  }

  let tail = end;
  for (let i = end - 1; i >= start; i--) {
    if (arr[i] === maxValue) {
      tail--;
      [arr[i], arr[tail]] = [arr[tail], arr[i]];
    }
  }

  let a = start;
  let segmentEnd = tail;
  // False right after skipping a run of duplicates below means the next median-of-three should
  // refresh one of its two candidates, since reusing them would just compare equal again.
  let reuseMedianCandidates = true;

  while (true) {
    while (segmentEnd - a > INSERTION_THRESHOLD) {
      if (!reuseMedianCandidates) {
        const m = Math.floor((a + a + segmentEnd) / 3);
        [arr[a], arr[m]] = [arr[m], arr[a]];
      }
      segmentEnd = partition(arr, a, segmentEnd, tail);
    }

    binaryInsertionSort(arr, a, segmentEnd);

    a = segmentEnd + 1;
    if (a >= tail) {
      if (a - 1 < tail) {
        [arr[a - 1], arr[tail]] = [arr[tail], arr[a - 1]];
      }
      return;
    }

    segmentEnd = lowerBoundIndex(arr, a, tail, a - 1);
    [arr[a - 1], arr[tail]] = [arr[tail], arr[a - 1]];

    reuseMedianCandidates = true;
    while (a < segmentEnd && arr[a - 1] === arr[a]) {
      reuseMedianCandidates = false;
      a++;
    }
    if (a === segmentEnd) reuseMedianCandidates = true;
  }
}

function sort(arr) {
  const n = arr.length;
  if (n < 2) return;
  quickSort(arr, 0, n);
}

var array = [
  55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51,
  66, 29, 44, 12, 78, 33, 91, 6, 58, 12,
];
sort(array);
console.log("[" + array.join(", ") + "]");
