const RADIX_BASE = 10;

// Extracts the digit at `place` (0 = ones place) from `value`, in RADIX_BASE.
function digitAt(value, place) {
  let divisor = 1;
  for (let i = 0; i < place; i++) {
    divisor *= RADIX_BASE;
  }
  return Math.floor(value / divisor) % RADIX_BASE;
}

// Swaps the two equal-length adjacent blocks [a, a+len) and [b, b+len).
function multiSwap(arr, a, b, len) {
  for (let i = 0; i < len; i++) {
    const t = arr[a + i];
    arr[a + i] = arr[b + i];
    arr[b + i] = t;
  }
}

// Rotates the adjacent blocks [a, m) and [m, b) into swapped order in place,
// using only block-swaps -- no auxiliary buffer.
function rotateBlock(arr, a, m, b) {
  let l = m - a;
  let r = b - m;
  while (l > 0 && r > 0) {
    if (r < l) {
      multiSwap(arr, m - r, m, r);
      b -= r;
      m -= r;
      l -= r;
    } else {
      multiSwap(arr, a, m, l);
      a += l;
      m += l;
      r -= l;
    }
  }
}

// Finds the leftmost index in [a, b) whose digit-`place` value is >= d,
// assuming [a, b) is already sorted by that digit.
function digitLowerBound(arr, a, b, d, place) {
  while (a < b) {
    const mid = Math.floor((a + b) / 2);
    if (digitAt(arr[mid], place) >= d) {
      b = mid;
    } else {
      a = mid + 1;
    }
  }
  return a;
}

// Merges the two adjacent digit-sorted runs [a, m) and [m, b), whose digit-`place`
// values are known to lie in [da, db), by rotating the below-threshold prefixes of
// both runs together and recursing into the two halves that produces.
function mergeByDigit(arr, a, m, b, da, db, place) {
  if (b - a < 2 || db - da < 2) {
    return;
  }
  const dm = Math.floor((da + db) / 2);
  const m1 = digitLowerBound(arr, a, m, dm, place);
  const m2 = digitLowerBound(arr, m, b, dm, place);
  rotateBlock(arr, m1, m, m2);
  const newM = m1 + (m2 - m);
  mergeByDigit(arr, newM, m2, b, dm, db, place);
  mergeByDigit(arr, a, m1, newM, da, dm, place);
}

// Sorts [a, b) by digit-`place` alone via ordinary merge-sort recursion on the
// index range, merging with mergeByDigit instead of a linear merge.
function digitMergeSort(arr, a, b, place) {
  if (b - a < 2) {
    return;
  }
  const mid = Math.floor((a + b) / 2);
  digitMergeSort(arr, a, mid, place);
  digitMergeSort(arr, mid, b, place);
  mergeByDigit(arr, a, mid, b, 0, RADIX_BASE, place);
}

function sort(arr) {
  const n = arr.length;
  if (n < 2) {
    return;
  }
  let maxValue = arr[0];
  for (let i = 1; i < n; i++) {
    if (arr[i] > maxValue) {
      maxValue = arr[i];
    }
  }
  let maxPlace = 0;
  let probe = RADIX_BASE;
  while (probe <= maxValue) {
    maxPlace++;
    probe *= RADIX_BASE;
  }
  for (let place = 0; place <= maxPlace; place++) {
    digitMergeSort(arr, 0, n, place);
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
