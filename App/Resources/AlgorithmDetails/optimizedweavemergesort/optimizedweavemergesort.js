function insertTo(array, a, b) {
  var temp = array[a];
  while (a > b) {
    a--;
    array[a + 1] = array[a];
  }
  array[b] = temp;
}

function multiSwap(array, a, b, len) {
  for (var i = 0; i < len; i++) {
    [array[a + i], array[b + i]] = [array[b + i], array[a + i]];
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

function bitReversal(array, a, b) {
  var len = b - a;
  var m = 0;
  var d1 = len >> 1;
  var d2 = d1 + (d1 >> 1);
  var i = 1;
  while (i < len - 1) {
    var j = d1;
    var k = i;
    var nn = d2;
    while ((k & 1) === 0) {
      j -= nn;
      k >>= 1;
      nn >>= 1;
    }
    m += j;
    if (m > i) {
      [array[a + i], array[a + m]] = [array[a + m], array[a + i]];
    }
    i++;
  }
}

function weaveInsert(array, a, b, rightInit) {
  var right = rightInit;
  var i = a;
  var j = a + 1;
  while (j < b) {
    if (right) {
      while (i < j && array[i] <= array[j]) i++;
    } else {
      while (i < j && array[i] < array[j]) i++;
    }
    if (i === j) {
      right = !right;
      j++;
    } else {
      insertTo(array, j, i);
      i++;
      j += 2;
    }
  }
}

function weaveMerge(array, a, mInit, b) {
  if (b - a < 2) return;
  var a1 = a;
  var b1 = b;
  var right = true;
  if ((b - a) % 2 === 1) {
    if (mInit - a < b - mInit) {
      a1 -= 1;
      right = false;
    } else {
      b1 += 1;
    }
  }
  var e = b1;
  while (e - a1 > 2) {
    var m = Math.floor((a1 + e) / 2);
    var p = 1;
    while (p * 2 <= m - a1) p *= 2;
    rotate(array, m - p, m, e - p);
    m = e - p;
    var f = m - p;
    bitReversal(array, f, m);
    bitReversal(array, m, e);
    bitReversal(array, f, e);
    e = f;
  }
  weaveInsert(array, a, b, right);
}

function sort(arr) {
  var n = arr.length;
  if (n <= 1) return arr;
  var d = 1;
  while (d < n) d <<= 1;
  while (d > 1) {
    var i = 0;
    var dec = 0;
    while (i < n) {
      var j = i;
      dec += n;
      while (dec >= d) {
        dec -= d;
        j++;
      }
      var k = j;
      dec += n;
      while (dec >= d) {
        dec -= d;
        k++;
      }
      weaveMerge(arr, i, j, k);
      i = k;
    }
    d = Math.floor(d / 2);
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
