function intPow(base, exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}

function getDigit(value, place, base) {
  return Math.floor(value / intPow(base, place)) % base;
}

function multiSwap(arr, a, b, len) {
  for (var i = 0; i < len; i++) {
    var t = arr[a + i];
    arr[a + i] = arr[b + i];
    arr[b + i] = t;
  }
}

function rotate(arr, a, m, b) {
  var l = m - a;
  var r = b - m;
  while (l > 0 && r > 0) {
    if (r < l) {
      multiSwap(arr, m - r, m, r);
      b -= r;
      m -= r;
      l -= r;
    } else {
      multiSwap(arr, a, m, l);
      a += l;
      m += l;
      r -= l;
    }
  }
}

function binSearchDigit(arr, a, b, d, place, base) {
  while (a < b) {
    var mid = Math.floor((a + b) / 2);
    if (getDigit(arr[mid], place, base) >= d) {
      b = mid;
    } else {
      a = mid + 1;
    }
  }
  return a;
}

function mergeDigit(arr, a, m, b, da, db, place, base) {
  if (b - a < 2 || db - da < 2) {
    return;
  }
  var dm = Math.floor((da + db) / 2);
  var m1 = binSearchDigit(arr, a, m, dm, place, base);
  var m2 = binSearchDigit(arr, m, b, dm, place, base);
  rotate(arr, m1, m, m2);
  var newM = m1 + (m2 - m);
  mergeDigit(arr, newM, m2, b, dm, db, place, base);
  mergeDigit(arr, a, m1, newM, da, dm, place, base);
}

function mergeSortDigit(arr, a, b, place, base) {
  if (b - a < 2) {
    return;
  }
  var mid = Math.floor((a + b) / 2);
  mergeSortDigit(arr, a, mid, place, base);
  mergeSortDigit(arr, mid, b, place, base);
  mergeDigit(arr, a, mid, b, 0, base, place, base);
}

// Digit-sorts [a, b) in place by `place` using rotation instead of counting
// buckets, then recurses into every resulting digit bucket one place lower --
// an ordinary MSD radix sort built entirely out of the LSD variant's
// rotate/binary-search machinery.
function msdRotateSort(arr, a, b, place, base) {
  if (b - a < 2 || place < 0) {
    return;
  }
  mergeSortDigit(arr, a, b, place, base);
  var start = a;
  for (var d = 0; d < base; d++) {
    var end = binSearchDigit(arr, start, b, d + 1, place, base);
    msdRotateSort(arr, start, end, place - 1, base);
    start = end;
  }
}

function sort(arr) {
  if (arr.length <= 1) {
    return arr;
  }
  var base = 4;
  var maxValue = Math.max.apply(null, arr);
  var highestPlace = 0;
  var probe = base;
  while (probe <= maxValue) {
    highestPlace++;
    probe *= base;
  }
  msdRotateSort(arr, 0, arr.length, highestPlace, base);
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
