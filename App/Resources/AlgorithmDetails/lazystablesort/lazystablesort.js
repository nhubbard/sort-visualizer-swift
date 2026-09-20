function multiSwap(arr, a, b, count) {
  for (let i = 0; i < count; i++) {
    [arr[a + i], arr[b + i]] = [arr[b + i], arr[a + i]];
  }
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
  let left = 0;
  let right = len;
  while (left < right) {
    const mid = left + Math.floor((right - left) / 2);
    const cond = isLeft
      ? arr[pos + mid] < arr[keyPos]
      : arr[pos + mid] <= arr[keyPos];
    if (cond) left = mid + 1;
    else right = mid;
  }
  return left;
}

function mergeWithoutBuffer(arr, pos, len1, len2) {
  if (len1 < len2) {
    while (len1 !== 0) {
      const loc = binSearch(arr, pos + len1, len2, pos, true);
      if (loc !== 0) { rotate(arr, pos, len1, loc); pos += loc; len2 -= loc; }
      if (len2 === 0) break;
      do { pos++; len1--; } while (len1 !== 0 && arr[pos] <= arr[pos + len1]);
    }
  } else {
    while (len2 !== 0) {
      const loc = binSearch(arr, pos, len1, pos + len1 + len2 - 1, false);
      if (loc !== len1) { rotate(arr, pos + loc, len1 - loc, len2); len1 = loc; }
      if (len1 === 0) break;
      do { len2--; } while (len2 !== 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1]);
    }
  }
}

function sort(arr) {
  const n = arr.length;
  let dist = 1;
  while (dist < n) {
    if (arr[dist - 1] > arr[dist]) {
      [arr[dist - 1], arr[dist]] = [arr[dist], arr[dist - 1]];
    }
    dist += 2;
  }
  let part = 2;
  while (part < n) {
    let left = 0;
    const right = n - 2 * part;
    while (left <= right) {
      mergeWithoutBuffer(arr, left, part, part);
      left += 2 * part;
    }
    const rest = n - left;
    if (rest > part) mergeWithoutBuffer(arr, left, part, rest - part);
    part *= 2;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
