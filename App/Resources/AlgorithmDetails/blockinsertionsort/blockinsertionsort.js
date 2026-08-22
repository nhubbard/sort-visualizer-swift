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
  if (len1 === 0 || len2 === 0) return;
  if (len1 === 1) {
    const loc = binSearch(arr, pos + 1, len2, pos, true);
    rotate(arr, pos, 1, loc);
    return;
  }
  if (len2 === 1) {
    const loc = binSearch(arr, pos, len1, pos + len1, false);
    rotate(arr, pos + loc, len1 - loc, 1);
    return;
  }
  const mid1 = Math.floor(len1 / 2);
  const loc = binSearch(arr, pos + len1, len2, pos + mid1, true);
  rotate(arr, pos + mid1, len1 - mid1, loc);
  mergeWithoutBuffer(arr, pos, mid1, loc);
  mergeWithoutBuffer(arr, pos + mid1 + loc, len1 - mid1, len2 - loc);
}

function findRun(arr, a, b) {
  let i = a + 1;
  if (i === b) return i;
  if (arr[i - 1] > arr[i]) {
    i++;
    while (i < b && arr[i - 1] > arr[i]) i++;
    let lo = a;
    let hi = i - 1;
    while (lo < hi) {
      [arr[lo], arr[hi]] = [arr[hi], arr[lo]];
      lo++;
      hi--;
    }
  } else {
    i++;
    while (i < b && arr[i - 1] <= arr[i]) i++;
  }
  return i;
}

function insert1(arr, a, l) {
  const tmp = arr[l];
  l--;
  while (l >= a && arr[l] > tmp) {
    arr[l + 1] = arr[l];
    l--;
  }
  arr[l + 1] = tmp;
}

function insert2(arr, a, l, r) {
  const tmpL = arr[l];
  const tmpR = arr[r];
  l--;
  while (l >= a && arr[l] > tmpR) {
    arr[l + 2] = arr[l];
    l--;
  }
  arr[l + 2] = tmpR;
  while (l >= a && arr[l] > tmpL) {
    arr[l + 1] = arr[l];
    l--;
  }
  arr[l + 1] = tmpL;
}

function sort(arr) {
  const n = arr.length;
  let i = findRun(arr, 0, n);
  while (i < n) {
    const j = findRun(arr, i, n);
    const len = j - i;
    if (len === 1) insert1(arr, 0, i);
    else if (len === 2) insert2(arr, 0, i, i + 1);
    else mergeWithoutBuffer(arr, 0, i, len);
    i = j;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
