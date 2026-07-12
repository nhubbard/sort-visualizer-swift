function greatestPowerOfTwoLessThan(n) {
  var k = 1;
  while (k < n) {
    k <<= 1;
  }
  return k >> 1;
}

function compare(array, i, j, dir) {
  var isGreater = array[i] > array[j];
  if (dir === isGreater) {
    [array[i], array[j]] = [array[j], array[i]];
  }
}

function bitonicMerge(array, lo, n, dir) {
  if (n > 1) {
    var m = greatestPowerOfTwoLessThan(n);
    for (var i = lo; i < lo + n - m; i++) {
      compare(array, i, i + m, dir);
    }
    bitonicMerge(array, lo, m, dir);
    bitonicMerge(array, lo + m, n - m, dir);
  }
}

function bitonicSort(array, lo, n, dir) {
  if (n > 1) {
    var m = Math.floor(n / 2);
    bitonicSort(array, lo, m, !dir);
    bitonicSort(array, lo + m, n - m, dir);
    bitonicMerge(array, lo, n, dir);
  }
}

function sort(arr) {
  bitonicSort(arr, 0, arr.length, true);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
