function ceilLog(n) {
  var i = 0;
  while (1 << i < n) {
    i++;
  }
  return i;
}

function multiSwap(array, a, b, len) {
  for (var i = 0; i < len; i++) {
    [array[a + i], array[b + i]] = [array[b + i], array[a + i]];
  }
}

function insertTo(array, a, b) {
  var temp = array[a];
  while (a > b) {
    a--;
    array[a + 1] = array[a];
  }
  array[b] = temp;
}

function binarySearch(array, start, end, value, left) {
  var a = start;
  var b = end;
  while (a < b) {
    var m = a + Math.floor((b - a) / 2);
    var comp = left ? value <= array[m] : value < array[m];
    if (comp) {
      b = m;
    } else {
      a = m + 1;
    }
  }
  return a;
}

function binaryInsertion(array, a, b) {
  var i = a + 1;
  while (i < b) {
    var value = array[i];
    insertTo(array, i, binarySearch(array, a, i, value, false));
    i++;
  }
}

function merge(array, a, m, b, p) {
  var i = a;
  var j = m;
  while (i < m && j < b) {
    if (array[i] <= array[j]) {
      [array[p], array[i]] = [array[i], array[p]];
      p++;
      i++;
    } else {
      [array[p], array[j]] = [array[j], array[p]];
      p++;
      j++;
    }
  }
  var leftover = 0;
  while (i < m) {
    [array[p], array[i]] = [array[i], array[p]];
    p++;
    i++;
  }
  while (j < b) {
    [array[p], array[j]] = [array[j], array[p]];
    p++;
    j++;
    leftover++;
  }
  return leftover;
}

function mergeWithBufStatic(array, a, m, b, p, useBinarySearch) {
  var i = 0;
  var j = m;
  var k = a;
  if (useBinarySearch) {
    while (i < m - a && j < b) {
      if (array[j] < array[p + i]) {
        var value = array[p + i];
        var q = binarySearch(array, j, b, value, true);
        while (j < q) {
          [array[k], array[j]] = [array[j], array[k]];
          k++;
          j++;
        }
      }
      [array[k], array[p + i]] = [array[p + i], array[k]];
      k++;
      i++;
    }
    while (i < m - a) {
      [array[k], array[p + i]] = [array[p + i], array[k]];
      k++;
      i++;
    }
  } else {
    while (i < m - a && j < b) {
      if (array[p + i] <= array[j]) {
        [array[k], array[p + i]] = [array[p + i], array[k]];
        k++;
        i++;
      } else {
        [array[k], array[j]] = [array[j], array[k]];
        k++;
        j++;
      }
    }
    while (i < m - a) {
      [array[k], array[p + i]] = [array[p + i], array[k]];
      k++;
      i++;
    }
  }
}

function mergeSort(array, a, p, length) {
  var j = 16;
  var ceilLogValue = ceilLog(length);
  var pos = length > 16 && (ceilLogValue & 1) === 1 ? p : a;

  var i = pos;
  while (i + 16 <= pos + length) {
    binaryInsertion(array, i, i + 16);
    i += 16;
  }
  binaryInsertion(array, i, pos + length);

  var nxt = pos;
  while (j < length) {
    pos = nxt;
    nxt ^= a ^ p;
    var posNext = nxt;

    i = pos;
    while (i + 2 * j <= pos + length) {
      merge(array, i, i + j, i + 2 * j, posNext);
      i += 2 * j;
      posNext += 2 * j;
    }
    if (i + j < pos + length) {
      merge(array, i, i + j, pos + length, posNext);
    } else {
      while (i < pos + length) {
        [array[i], array[posNext]] = [array[posNext], array[i]];
        i++;
        posNext++;
      }
    }
    j *= 2;
  }
}

function bufferedMerge(array, a, b) {
  if (b - a <= 16) {
    binaryInsertion(array, a, b);
    return;
  }

  var m = Math.floor((a + b + 1) / 2);
  mergeSort(array, m, 2 * m - b, b - m);

  var n = Math.floor((a + m + 1) / 2);
  var limit = Math.floor((b - a) / 16);
  while (m - a > limit) {
    mergeSort(array, 2 * n - m, n, m - n);
    mergeWithBufStatic(
      array,
      n,
      m,
      b,
      2 * n - m,
      Math.floor((b - m) / (m - n)) >= ceilLog(n - a),
    );
    m = n;
    n = Math.floor((a + m + 1) / 2);
  }

  bufferedMerge(array, a, m);
  multiSwap(array, a, b - (m - a), m - a);
  var s = merge(array, m, b - (m - a), b, a);
  bufferedMerge(array, b - (m - a) - s, b);
}

function sort(arr) {
  var n = arr.length;
  if (n <= 1) return arr;
  bufferedMerge(arr, 0, n);
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
