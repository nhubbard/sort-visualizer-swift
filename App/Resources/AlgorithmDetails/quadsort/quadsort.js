const INSERTION_RUN = 4;

function insertionSortRange(arr, lo, hi) {
  for (let i = lo + 1; i < hi; i++) {
    const key = arr[i];
    let j = i - 1;
    while (j >= lo && arr[j] > key) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[j + 1] = key;
  }
}

// Merges the two equal-length sorted runs source[lo..lo+runLength) and
// source[lo+runLength..lo+2*runLength) into dest, filling from both ends toward the middle at
// once instead of scanning front to back alone.
function parityMerge(source, lo, runLength, dest) {
  let left = lo;
  let right = lo + runLength;
  let leftEnd = lo + runLength - 1;
  let rightEnd = lo + 2 * runLength - 1;
  let front = lo;
  let back = lo + 2 * runLength - 1;

  for (let step = 0; step < runLength; step++) {
    if (source[left] <= source[right]) {
      dest[front] = source[left];
      left++;
    } else {
      dest[front] = source[right];
      right++;
    }
    front++;

    if (source[leftEnd] > source[rightEnd]) {
      dest[back] = source[leftEnd];
      leftEnd--;
    } else {
      dest[back] = source[rightEnd];
      rightEnd--;
    }
    back--;
  }
}

function mergeRange(source, lo, mid, hi, dest) {
  let left = lo;
  let right = mid;
  let out = lo;
  while (left < mid && right < hi) {
    if (source[left] <= source[right]) {
      dest[out] = source[left];
      left++;
    } else {
      dest[out] = source[right];
      right++;
    }
    out++;
  }
  while (left < mid) {
    dest[out] = source[left];
    left++;
    out++;
  }
  while (right < hi) {
    dest[out] = source[right];
    right++;
    out++;
  }
}

function sort(arr) {
  const n = arr.length;
  if (n < 2) return;
  let buffer = arr.slice();

  let lo = 0;
  while (lo < n) {
    insertionSortRange(arr, lo, Math.min(lo + INSERTION_RUN, n));
    lo += INSERTION_RUN;
  }

  let runLength = INSERTION_RUN;
  while (runLength < n) {
    lo = 0;
    while (lo < n) {
      const mid = Math.min(lo + runLength, n);
      const hi = Math.min(lo + runLength * 2, n);
      if (mid - lo === runLength && hi - mid === runLength) {
        parityMerge(arr, lo, runLength, buffer);
      } else if (mid < hi) {
        mergeRange(arr, lo, mid, hi, buffer);
      } else {
        for (let i = lo; i < mid; i++) {
          buffer[i] = arr[i];
        }
      }
      lo += runLength * 2;
    }
    for (let i = 0; i < n; i++) {
      arr[i] = buffer[i];
    }
    runLength *= 2;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
