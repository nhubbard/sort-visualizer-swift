function leftBinarySearch(array, a, b, val) {
  let lo = a, hi = b;
  while (lo < hi) {
    const mid = lo + Math.floor((hi - lo) / 2);
    if (val <= array[mid]) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

function rightBinarySearch(array, a, b, val) {
  let lo = a, hi = b;
  while (lo < hi) {
    const mid = lo + Math.floor((hi - lo) / 2);
    if (val < array[mid]) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

function insertToLeft(array, a, b, temp) {
  while (a > b) {
    array[a] = array[a - 1];
    a -= 1;
  }
  array[b] = temp;
}

function insertToRight(array, a, b, temp) {
  while (a < b) {
    array[a] = array[a + 1];
    a += 1;
  }
  array[a] = temp;
}

function doubleInsertion(array, a, b) {
  if (b - a < 2) {
    return;
  }

  let j = a + Math.floor((b - a - 2) / 2) + 1;
  let i = a + Math.floor((b - a - 1) / 2);

  if (j > i && array[i] > array[j]) {
    [array[i], array[j]] = [array[j], array[i]];
  }
  i -= 1;
  j += 1;

  while (j < b) {
    if (array[i] > array[j]) {
      const l = array[j];
      const r = array[i];
      const m = rightBinarySearch(array, i + 1, j, l);
      insertToRight(array, i, m - 1, l);
      const dest = leftBinarySearch(array, m, j, r);
      insertToLeft(array, j, dest, r);
    } else {
      const l = array[i];
      const r = array[j];
      const m = leftBinarySearch(array, i + 1, j, l);
      insertToRight(array, i, m - 1, l);
      const dest = rightBinarySearch(array, m, j, r);
      insertToLeft(array, j, dest, r);
    }
    i -= 1;
    j += 1;
  }
}

function sort(arr) {
  if (arr.length > 1) {
    doubleInsertion(arr, 0, arr.length);
  }
}

const array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log(array);
