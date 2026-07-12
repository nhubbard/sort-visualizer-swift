function compSwap(array, a, b, end) {
  if (b >= end) return;
  if (array[a] > array[b]) {
    var temp = array[a];
    array[a] = array[b];
    array[b] = temp;
  }
}

function rangeComp(array, a, b, offset, end) {
  var half = Math.floor((b - a) / 2);
  var m = a + half;
  var base = a + offset;
  for (var i = 0; i < half - offset; i++) {
    if ((i & ~offset) === i) {
      compSwap(array, base + i, m + i, end);
    }
  }
}

function sort(arr) {
  var end = arr.length;
  if (end <= 1) return arr;
  var paddedLength = 1;
  while (paddedLength < end) paddedLength <<= 1;

  for (var k = 2; k <= paddedLength; k *= 2) {
    for (var j = 0; j < k / 2; j++) {
      for (var i = 0; i + j < end; i += k) {
        rangeComp(arr, i, i + k, j, end);
      }
    }
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
