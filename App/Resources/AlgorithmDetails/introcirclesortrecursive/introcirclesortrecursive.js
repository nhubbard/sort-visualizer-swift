function circleSortRoutine(array, lo, hi, end) {
  if (lo === hi) return 0;
  var low = lo;
  var high = hi;
  var mid = Math.floor((hi - lo) / 2);
  var swapCount = 0;
  while (lo < hi) {
    if (hi < end && array[lo] > array[hi]) {
      [array[lo], array[hi]] = [array[hi], array[lo]];
      swapCount++;
    }
    lo++;
    hi--;
  }
  swapCount += circleSortRoutine(array, low, low + mid, end);
  if (low + mid + 1 < end) {
    swapCount += circleSortRoutine(array, low + mid + 1, high, end);
  }
  return swapCount;
}

function binaryInsertionSort(array, end) {
  for (var i = 1; i < end; i++) {
    var value = array[i];
    var lo = 0;
    var hi = i;
    while (lo < hi) {
      var mid = Math.floor(lo + (hi - lo) / 2);
      if (value < array[mid]) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    var j = i;
    while (j > lo) {
      array[j] = array[j - 1];
      j--;
    }
    array[lo] = value;
  }
}

function sort(arr) {
  var end = arr.length;
  if (end <= 1) return arr;
  var n = 1;
  var threshold = 0;
  while (n < end) {
    n <<= 1;
    threshold++;
  }
  threshold = Math.floor(threshold / 2);

  var iterations = 0;
  while (true) {
    iterations++;
    if (iterations >= threshold) {
      binaryInsertionSort(arr, end);
      return arr;
    }
    if (circleSortRoutine(arr, 0, n - 1, end) === 0) {
      return arr;
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
