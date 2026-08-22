function nextPowerOfTwo(n) {
  var k = 1;
  while (k < n) {
    k <<= 1;
  }
  return k;
}

function circleSortRoutine(array, lo, hi, end) {
  if (lo === hi) {
    return 0;
  }
  var low = lo;
  var high = hi;
  var mid = Math.floor((hi - lo) / 2);
  var swaps = 0;
  while (lo < hi) {
    if (hi < end && array[lo] > array[hi]) {
      [array[lo], array[hi]] = [array[hi], array[lo]];
      swaps++;
    }
    lo++;
    hi--;
  }
  swaps += circleSortRoutine(array, low, low + mid, end);
  if (low + mid + 1 < end) {
    swaps += circleSortRoutine(array, low + mid + 1, high, end);
  }
  return swaps;
}

function sort(arr) {
  var end = arr.length;
  if (end === 0) {
    return arr;
  }
  var paddedLength = nextPowerOfTwo(end);
  var swaps;
  do {
    swaps = circleSortRoutine(arr, 0, paddedLength - 1, end);
  } while (swaps !== 0);
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
