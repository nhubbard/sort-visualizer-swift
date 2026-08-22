function compSwap(array, a, b, end) {
  if (b < end && array[a] > array[b]) {
    var temp = array[a];
    array[a] = array[b];
    array[b] = temp;
  }
}

function pairwiseMerge(array, a, b, end) {
  var m = Math.floor((a + b) / 2);
  var m1 = Math.floor((a + m) / 2);
  var g = m - m1;

  for (var i = 0; i < m - m1; i++) {
    var j = m1;
    var k = g;
    while (k > 0) {
      compSwap(array, j + i, j + i + k, end);
      k >>= 1;
      j -= k - (i & k);
    }
  }
  if (b - a > 4) {
    pairwiseMerge(array, m, b, end);
  }
}

function pairwiseMergeSort(array, a, b, end) {
  var m = Math.floor((a + b) / 2);
  var i = a;
  var j = m;
  while (i < m) {
    compSwap(array, i, j, end);
    i++;
    j++;
  }
  if (b - a > 2) {
    pairwiseMergeSort(array, a, m, end);
    pairwiseMergeSort(array, m, b, end);
    pairwiseMerge(array, a, b, end);
  }
}

function sort(arr) {
  var length = arr.length;
  var end = length;

  var n = 1;
  while (n < length) n <<= 1;

  pairwiseMergeSort(arr, 0, n, end);
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
