function sort(arr) {
  const n = arr.length;
  if (n <= 1) return arr;
  const base = 4;
  const maxValue = Math.max(...arr);
  let q = 0, probe = base;
  while (probe <= maxValue) { q++; probe *= base; }
  let m = 0, i = 0, b = n;
  while (i < n) {
    const p = b - i < 1 ? i : dist(arr, i, b, q, base);
    if (q === 0) {
      m += base;
      let t = Math.floor(m / base);
      while (t % base === 0) { t = Math.floor(t / base); q++; }
      i = b;
      while (b < n && shift(arr[b], q + 1, base) === shift(m, q + 1, base)) b++;
    } else { b = p; q--; }
  }
  return arr;
}

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
function shift(value, places, base) {
  while (places-- > 0) value = Math.floor(value / base);
  return value;
}

function dist(arr, a, b, place, base) {
  mergeSortDigit(arr, a, b, place, base);
  return binSearchDigit(arr, a, b, 1, place, base);
}


const array = [
  0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
];
sort(array);
console.log("[" + array.join(", ") + "]");
