function compSwap(array, a, b, end) {
  if (b < end && array[a] > array[b]) {
    var temp = array[a];
    array[a] = array[b];
    array[b] = temp;
  }
}

function sort(arr) {
  var length = arr.length;
  var end = length;

  var n = 1;
  while (n < length) n <<= 1;

  var k = n >> 1;
  var j, i, m, p;
  while (k > 0) {
    j = 0;
    while (j < length) {
      for (i = 0; i < k; i++) {
        compSwap(arr, j + i, j + k + i, end);
      }
      j += k << 1;
    }
    k >>= 1;
  }

  k = 2;
  while (k < n) {
    m = k >> 1;
    while (m > 0) {
      j = 0;
      while (j < length) {
        p = m;
        while (p < (k - m) << 1) {
          for (i = 0; i < m; i++) {
            compSwap(arr, j + p + i, j + p + m + i, end);
          }
          p += m << 1;
        }
        j += k << 1;
      }
      m >>= 1;
    }
    k <<= 1;
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
