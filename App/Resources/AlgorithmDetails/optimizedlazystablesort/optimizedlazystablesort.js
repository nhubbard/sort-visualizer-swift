function swap(arr, a, b) {
  const t = arr[a];
  arr[a] = arr[b];
  arr[b] = t;
}

function multiSwap(arr, a, b, count) {
  for (let i = 0; i < count; i++) swap(arr, a + i, b + i);
}

function rotate(arr, pos, lenA, lenB) {
  while (lenA !== 0 && lenB !== 0) {
    if (lenA <= lenB) {
      multiSwap(arr, pos, pos + lenA, lenA);
      pos += lenA;
      lenB -= lenA;
    } else {
      multiSwap(arr, pos + (lenA - lenB), pos + lenA, lenB);
      lenA -= lenB;
    }
  }
}

function binSearch(arr, pos, len, keyPos, isLeft) {
  let left = -1;
  let right = len;
  const key = arr[keyPos];
  while (left < right - 1) {
    const mid = left + Math.floor((right - left) / 2);
    const cond = isLeft ? arr[pos + mid] >= key : arr[pos + mid] > key;
    if (cond) right = mid;
    else left = mid;
  }
  return right;
}

function mergeWithoutBuffer(arr, pos, len1, len2) {
  if (len1 === 0 || len2 === 0) return;
  if (len1 < len2) {
    while (len1 !== 0) {
      const loc = binSearch(arr, pos + len1, len2, pos, true);
      if (loc !== 0) {
        rotate(arr, pos, len1, loc);
        pos += loc;
        len2 -= loc;
      }
      if (len2 === 0) break;
      do {
        pos++;
        len1--;
      } while (len1 !== 0 && arr[pos] <= arr[pos + len1]);
    }
  } else {
    while (len2 !== 0) {
      const loc = binSearch(arr, pos, len1, pos + len1 + len2 - 1, false);
      if (loc !== len1) {
        rotate(arr, pos + loc, len1 - loc, len2);
        len1 = loc;
      }
      if (len1 === 0) break;
      do {
        len2--;
      } while (len2 !== 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1]);
    }
  }
}

// Guard: a chunk of length <= 1 has nothing to compare. ArrayV's own source skips this
// check and unconditionally reads arr[a] / arr[a + 1], which crashes whenever chunking
// leaves a trailing 1-element chunk (e.g. n = 17 leaves a final [16, 17) chunk).
function insertionSortChunk(arr, a, b) {
  if (b - a <= 1) return;
  let i = a + 1;
  const descending = arr[i - 1] > arr[i];
  i++;
  if (descending) {
    while (i < b && arr[i - 1] > arr[i]) i++;
    let lo = a,
      hi = i - 1;
    while (lo < hi) {
      swap(arr, lo, hi);
      lo++;
      hi--;
    }
  } else {
    while (i < b && arr[i - 1] <= arr[i]) i++;
  }
  while (i < b) {
    const current = arr[i];
    let pos = i - 1;
    while (pos >= a && arr[pos] > current) {
      arr[pos + 1] = arr[pos];
      pos--;
    }
    arr[pos + 1] = current;
    i++;
  }
}

function lazyStableSort(arr, pos, len) {
  let dist = 0;
  while (dist + 16 < len) {
    insertionSortChunk(arr, pos + dist, pos + dist + 16);
    dist += 16;
  }
  if (dist < len) insertionSortChunk(arr, pos + dist, pos + len);

  let part = 16;
  while (part < len) {
    let left = 0;
    let right = len - 2 * part;
    while (left <= right) {
      mergeWithoutBuffer(arr, pos + left, part, part);
      left += 2 * part;
    }
    const rest = len - left;
    if (rest > part) mergeWithoutBuffer(arr, pos + left, part, rest - part);
    part *= 2;
  }
}

function sort(arr) {
  const n = arr.length;
  lazyStableSort(arr, 0, n);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
