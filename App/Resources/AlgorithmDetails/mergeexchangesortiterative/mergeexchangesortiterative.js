function mergeExchangeSort(array) {
  var n = array.length;
  if (n <= 1) return;
  var t = Math.floor(Math.log(n - 1) / Math.log(2)) + 1;
  var p0 = 1 << (t - 1);
  for (var p = p0; p > 0; p >>= 1) {
    var q = p0;
    var r = 0;
    var d = p;
    while (true) {
      for (var i = 0; i < n - d; i++) {
        if ((i & p) === r && array[i] > array[i + d]) {
          var temp = array[i];
          array[i] = array[i + d];
          array[i + d] = temp;
        }
      }
      if (q === p) break;
      d = q - p;
      q >>= 1;
      r = p;
    }
  }
}

function sort(arr) {
  mergeExchangeSort(arr);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
