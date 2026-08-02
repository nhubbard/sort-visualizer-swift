function partition(array, lo, hi) {
  var pivot = array[hi];
  var i = lo;
  for (var j = lo; j < hi; j++) {
    if (array[j] < pivot) {
      [array[i], array[j]] = [array[j], array[i]];
      i++;
    }
  }
  [array[i], array[hi]] = [array[hi], array[i]];
  return i;
}

function quickSort(array, lo, hi) {
  if (lo < hi) {
    var p = partition(array, lo, hi);
    quickSort(array, lo, p - 1);
    quickSort(array, p + 1, hi);
  }
}

function sort(arr) {
  quickSort(arr, 0, arr.length - 1);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
