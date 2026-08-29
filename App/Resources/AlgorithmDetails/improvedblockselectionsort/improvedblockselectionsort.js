function blockRoot(n) {
  var i = 1;
  while (i * i < n) {
    i *= 2;
  }
  return i;
}

function multiSwap(array, a, b, length) {
  for (var i = 0; i < length; i++) {
    var temp = array[a + i];
    array[a + i] = array[b + i];
    array[b + i] = temp;
  }
}

function rotate(array, a, m, b) {
  var l = m - a;
  var r = b - m;
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

function selectRange(array, start, end, bLen) {
  var minIndex = start;
  var a = start + bLen;
  while (a < end) {
    if (array[a] < array[minIndex]) {
      minIndex = a;
    } else if (
      array[a] === array[minIndex] &&
      array[a + bLen - 1] < array[minIndex + bLen - 1]
    ) {
      minIndex = a;
    }
    a += bLen;
  }
  return minIndex;
}

function blockSelect(array, a, m, b, bLen) {
  var k = a;
  var j = m;
  while (k < m && array[k] <= array[m]) {
    k += bLen;
  }
  if (k === m) return;

  var i = m;
  multiSwap(array, k, j, bLen);
  k += bLen;
  j += bLen;

  while (k < j && j < b) {
    if (array[i] <= array[j]) {
      if (k !== i) multiSwap(array, k, i, bLen);
      k += bLen;
      i = selectRange(array, Math.max(m, k), j, bLen);
    } else {
      if (i === k) i = j;
      if (k !== j) multiSwap(array, k, j, bLen);
      k += bLen;
      j += bLen;
    }
  }

  while (k < j) {
    i = selectRange(array, k, b, bLen);
    if (k !== i) multiSwap(array, k, i, bLen);
    k += bLen;
  }
}

function inPlaceMerge(array, a, m, b) {
  var i = a;
  var j = m;
  while (i < j && j < b) {
    if (array[i] > array[j]) {
      var k = j + 1;
      while (k < b && array[i] > array[k]) {
        k++;
      }
      rotate(array, i, j, k);
      i += k - j;
      j = k;
    } else {
      i++;
    }
  }
  return i;
}

function inPlaceMergeBW(array, a, m, b) {
  var i = m - 1;
  var j = b - 1;
  while (j > i && i >= a) {
    if (array[i] > array[j]) {
      var k = i - 1;
      while (k >= a && array[k] > array[j]) {
        k--;
      }
      rotate(array, k + 1, i + 1, j + 1);
      j -= i - k;
      i = k;
    } else {
      j--;
    }
  }
}

function sort(arr) {
  var n = arr.length;
  if (n <= 1) return arr;
  var j = 1;
  while (j < n) {
    var bLen = blockRoot(j);
    var runLength = j;
    var b = n - (n % bLen);

    while (runLength > 16) {
      var i = 0;
      while (i + j < b) {
        var k = i;
        while (k + runLength < Math.min(i + 2 * j, b)) {
          blockSelect(
            arr,
            k,
            k + runLength,
            Math.min(k + 2 * runLength, b),
            bLen,
          );
          k += runLength;
        }
        i += 2 * j;
      }
      runLength = bLen;
      bLen = blockRoot(bLen);
    }

    var i2 = 0;
    while (i2 + j < b) {
      var k2 = i2;
      var f = i2;
      while (k2 + runLength < Math.min(i2 + 2 * j, b)) {
        f = inPlaceMerge(
          arr,
          f,
          k2 + runLength,
          Math.min(k2 + 2 * runLength, b),
        );
        k2 += runLength;
      }
      i2 += 2 * j;
    }

    inPlaceMergeBW(arr, n - (n % (2 * j)), b, n);
    j *= 2;
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
