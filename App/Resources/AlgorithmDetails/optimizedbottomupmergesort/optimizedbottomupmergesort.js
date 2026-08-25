const BLOCK_SIZE = 16;

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

function merge(src, dst, low, mid, high) {
  let i = low;
  let j = mid;
  let k = low;
  while (i < mid && j < high) {
    if (src[i] <= src[j]) {
      dst[k++] = src[i++];
    } else {
      dst[k++] = src[j++];
    }
  }
  while (i < mid) {
    dst[k++] = src[i++];
  }
  while (j < high) {
    dst[k++] = src[j++];
  }
}

function sort(arr) {
  const n = arr.length;
  if (n < BLOCK_SIZE) {
    binaryInsertionSort(arr, 0, n);
    return;
  }

  // Pre-pass: sort fixed-size blocks with binary insertion sort so the merge phase can
  // start from already-sorted runs instead of single elements.
  for (let low = 0; low < n; low += BLOCK_SIZE) {
    binaryInsertionSort(arr, low, Math.min(low + BLOCK_SIZE, n));
  }

  // Merge phase: ping-pong between arr and scratch, alternating direction every pass,
  // instead of always merging into scratch and copying the whole buffer back.
  let scratch = new Array(n).fill(0);
  let src = arr;
  let dst = scratch;
  let width = BLOCK_SIZE;
  let passes = 0;
  while (width < n) {
    for (let low = 0; low < n; low += 2 * width) {
      const mid = Math.min(low + width, n);
      const high = Math.min(low + 2 * width, n);
      if (mid < high) {
        merge(src, dst, low, mid, high);
      } else {
        for (let i = low; i < mid; i++) {
          dst[i] = src[i];
        }
      }
    }
    [src, dst] = [dst, src];
    width *= 2;
    passes++;
  }

  // An even number of passes lands the sorted result back in arr on its own; an odd
  // number leaves it in scratch, needing this one explicit copy back.
  if (passes % 2 === 1) {
    for (let i = 0; i < n; i++) {
      arr[i] = src[i];
    }
  }
}

var array = [
  81, 14, 3, 94, 35, 31, 28, 17, 94, 13, 86, 94, 69, 11, 75, 54, 4, 3, 11, 27,
  29, 64, 77, 3, 71, 25, 91, 83, 89, 69, 53, 28, 57, 75, 35, 0, 97, 20, 89, 54,
];
sort(array);
console.log("[" + array.join(", ") + "]");
