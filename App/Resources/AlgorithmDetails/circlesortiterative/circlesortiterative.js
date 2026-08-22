function circleSortRoutine(array, length, end) {
  var swapCount = 0;
  for (var gap = Math.floor(length / 2); gap > 0; gap = Math.floor(gap / 2)) {
    for (var start = 0; start + gap < end; start += 2 * gap) {
      var low = start;
      var high = start + 2 * gap - 1;
      while (low < high) {
        if (high < end && array[low] > array[high]) {
          [array[low], array[high]] = [array[high], array[low]];
          swapCount++;
        }
        low++;
        high--;
      }
    }
  }
  return swapCount;
}

function sort(arr) {
  var end = arr.length;
  if (end <= 1) return arr;
  var n = 1;
  while (n < end) {
    n <<= 1;
  }

  var numberOfSwaps = 1;
  while (numberOfSwaps !== 0) {
    numberOfSwaps = circleSortRoutine(arr, n, end);
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
