function multiSwap(array, a, b, len) {
  for (var i = 0; i < len; i++) {
    var t = array[a + i];
    array[a + i] = array[b + i];
    array[b + i] = t;
  }
}

function binarySearchMid(array, start, mid, end) {
  var a = 0;
  var b = Math.min(mid - start, end - mid);
  var m = a + Math.floor((b - a) / 2);
  while (b > a) {
    if (array[mid - m - 1] > array[mid + m]) {
      a = m + 1;
    } else {
      b = m;
    }
    m = a + Math.floor((b - a) / 2);
  }
  return m;
}

function multiSwapMerge(array, start, mid, end) {
  var m = binarySearchMid(array, start, mid, end);
  while (m > 0) {
    multiSwap(array, mid - m, mid, m);
    multiSwapMerge(array, mid, mid + m, end);
    end = mid;
    mid -= m;
    m = binarySearchMid(array, start, mid, end);
  }
}

function multiSwapMergeSort(array, a, b) {
  var len = b - a;
  for (var j = 1; j < len; j *= 2) {
    var i;
    for (i = a; i + 2 * j <= b; i += 2 * j) {
      multiSwapMerge(array, i, i + j, i + 2 * j);
    }
    if (i + j < b) {
      multiSwapMerge(array, i, i + j, b);
    }
  }
}

function sort(arr) {
  multiSwapMergeSort(arr, 0, arr.length);
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
