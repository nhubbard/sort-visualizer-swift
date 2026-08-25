function binaryInsertionSort(arr, lo, hi) {
  for (let i = lo + 1; i < hi; i++) {
    const key = arr[i];
    let left = lo;
    let right = i;
    while (left < right) {
      const mid = Math.floor((left + right) / 2);
      if (arr[mid] <= key) {
        left = mid + 1;
      } else {
        right = mid;
      }
    }
    for (let j = i; j > left; j--) {
      arr[j] = arr[j - 1];
    }
    arr[left] = key;
  }
}

function swapRange(arr, a, b, length) {
  for (let i = 0; i < length; i++) {
    const t = arr[a + i];
    arr[a + i] = arr[b + i];
    arr[b + i] = t;
  }
}

function rotate(arr, lo, mid, hi) {
  // Swaps the two adjacent blocks arr[lo..mid) and arr[mid..hi) so their order is
  // reversed, using no auxiliary storage: the smaller of the two remaining pieces is
  // always swapped whole against an equal-sized piece of the other, which shrinks one
  // piece to nothing a little at a time until both are exhausted.
  let i = mid - lo;
  let j = hi - mid;
  if (i === 0 || j === 0) {
    return;
  }
  while (i !== j) {
    if (i < j) {
      swapRange(arr, mid - i, mid + j - i, i);
      j -= i;
    } else {
      swapRange(arr, mid - i, mid, j);
      i -= j;
    }
  }
  swapRange(arr, mid - i, mid, i);
}

function gallop(arr, lo, hi, value) {
  // First index in [lo, hi) whose element is not less than `value`, found by doubling
  // the step size until it overshoots and then binary-searching the resulting bracket,
  // rather than scanning one element at a time. Assumes arr[lo] < value.
  let left = lo;
  let step = 1;
  let right = lo + step;
  while (right < hi && arr[right] < value) {
    left = right;
    step *= 2;
    right = lo + step;
  }
  right = Math.min(right, hi);
  while (right - left > 1) {
    const mid = Math.floor((left + right) / 2);
    if (arr[mid] < value) {
      left = mid;
    } else {
      right = mid;
    }
  }
  return right;
}

function merge(arr, lo, mid, hi) {
  // Merges the sorted run arr[lo..mid) into the sorted run arr[mid..hi) in place. `left`
  // tracks the first not-yet-placed element of the left run, and `right` tracks the
  // start of the not-yet-consumed remainder of the right run.
  let left = lo;
  let right = mid;
  while (left < right && right < hi) {
    if (arr[left] <= arr[right]) {
      left++;
    } else {
      const boundary = gallop(arr, right, hi, arr[left]);
      rotate(arr, left, right, boundary);
      left += boundary - right;
      right = boundary;
    }
  }
}

function integerSqrt(n) {
  let r = Math.floor(Math.sqrt(n));
  while ((r + 1) * (r + 1) <= n) {
    r++;
  }
  while (r * r > n) {
    r--;
  }
  return r;
}

function sort(arr) {
  const n = arr.length;
  if (n <= 16) {
    binaryInsertionSort(arr, 0, n);
    return;
  }

  const blockSize = Math.max(16, integerSqrt(n));
  for (let low = 0; low < n; low += blockSize) {
    binaryInsertionSort(arr, low, Math.min(low + blockSize, n));
  }

  // Merge blocks back to front: the already-sorted run always starts at `mergedStart`,
  // and each step folds the block immediately before it into that run.
  const numBlocks = Math.ceil(n / blockSize);
  let mergedStart = (numBlocks - 1) * blockSize;
  for (let i = numBlocks - 2; i >= 0; i--) {
    const leftStart = i * blockSize;
    merge(arr, leftStart, mergedStart, n);
    mergedStart = leftStart;
  }
}

var array = [
  55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51,
  66, 29, 44, 12,
];
sort(array);
console.log("[" + array.join(", ") + "]");
