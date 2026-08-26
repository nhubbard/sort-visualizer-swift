const INSERTION_THRESHOLD = 16;

function medianOfThree(arr, start, end) {
  // Arranges arr[start], arr[mid], arr[end - 1] so the median of the three ends up at `start`,
  // ready to serve as partition's pivot.
  const mid = start + Math.floor((end - 1 - start) / 2);
  if (arr[start] > arr[mid]) {
    [arr[start], arr[mid]] = [arr[mid], arr[start]];
  }
  if (arr[mid] > arr[end - 1]) {
    [arr[mid], arr[end - 1]] = [arr[end - 1], arr[mid]];
    if (arr[start] > arr[mid]) {
      return;
    }
  }
  [arr[start], arr[mid]] = [arr[mid], arr[start]];
}

function partition(arr, start, end) {
  // Classic two-pointer Hoare partition against the pivot medianOfThree just placed at `start`.
  // Returns the pivot's final resting index.
  medianOfThree(arr, start, end);
  const pivot = arr[start];
  let i = start;
  let j = end;

  while (true) {
    i++;
    while (i < j && arr[i] < pivot) {
      i++;
    }
    j--;
    while (j >= i && arr[j] >= pivot) {
      j--;
    }
    if (i < j) {
      [arr[i], arr[j]] = [arr[j], arr[i]];
    } else {
      [arr[start], arr[j]] = [arr[j], arr[start]];
      return j;
    }
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

function quickSort(arr, start, end) {
  // Sorts arr[start..end) in place with no recursion: a single loop processes one segment at a
  // time, shrinking and partitioning it down to INSERTION_THRESHOLD elements, finishing with
  // binaryInsertionSort, then advancing past it to the next segment.

  // Move every copy of this range's maximum value to the very end first. Those elements are
  // already correctly placed relative to everything else, so the rest of the algorithm never
  // has to look at them again -- and the boundary in front of them becomes the fixed resting
  // place partition sends each finished pivot out to.
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
  // refresh its candidates, since reusing them would just compare equal again.
  let refreshMedian = true;

  while (true) {
    while (segmentEnd - a > INSERTION_THRESHOLD) {
      if (refreshMedian) {
        medianOfThree(arr, a, segmentEnd);
      }
      const pivotIndex = partition(arr, a, segmentEnd);
      [arr[pivotIndex], arr[tail]] = [arr[tail], arr[pivotIndex]];
      segmentEnd = pivotIndex;
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

    refreshMedian = true;
    while (a < segmentEnd && arr[a - 1] === arr[a]) {
      refreshMedian = false;
      a++;
    }
    if (a === segmentEnd) refreshMedian = true;
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
