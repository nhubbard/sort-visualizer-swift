function multiSwap(array, a, b, len) {
  for (var i = 0; i < len; i++) {
    var t = array[a + i];
    array[a + i] = array[b + i];
    array[b + i] = t;
  }
}

function rotate(array, a, m, b) {
  var l = m - a, r = b - m;
  while (l > 0 && r > 0) {
    if (r < l) {
      multiSwap(array, m - r, m, r);
      b -= r;
      m -= r;
      l -= r;
    } else {
      multiSwap(array, a, m, l);
      a += l;
      m += l;
      r -= l;
    }
  }
}

function binarySearch(array, a, b, value, left) {
  while (a < b) {
    var mid = a + Math.floor((b - a) / 2);
    var comp = left ? value <= array[mid] : value < array[mid];
    if (comp) {
      b = mid;
    } else {
      a = mid + 1;
    }
  }
  return a;
}

function rotateMerge(array, a, m, b) {
  var m1, m2, m3, value;
  if (m - a >= b - m) {
    m1 = a + Math.floor((m - a) / 2);
    value = array[m1];
    m2 = binarySearch(array, m, b, value, true);
    m3 = m1 + (m2 - m);
  } else {
    m2 = m + Math.floor((b - m) / 2);
    value = array[m2];
    m1 = binarySearch(array, a, m, value, false);
    m3 = m2 - (m - m1);
    m2 = m2 + 1;
  }
  rotate(array, m1, m, m2);
  if (m2 - (m3 + 1) > 0 && b - m2 > 0) {
    rotateMerge(array, m3 + 1, m2, b);
  }
  if (m1 - a > 0 && m3 - m1 > 0) {
    rotateMerge(array, a, m1, m3);
  }
}

function rotateMergeSort(array, a, b) {
  var len = b - a;
  for (var j = 1; j < len; j *= 2) {
    var i;
    for (i = a; i + 2 * j <= b; i += 2 * j) {
      rotateMerge(array, i, i + j, i + 2 * j);
    }
    if (i + j < b) {
      rotateMerge(array, i, i + j, b);
    }
  }
}

function sort(arr) {
  rotateMergeSort(arr, 0, arr.length);
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
