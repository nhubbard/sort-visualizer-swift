function multiSwap(array, a, b, len) {
  for (var i = 0; i < len; i++) {
    var t = array[a + i];
    array[a + i] = array[b + i];
    array[b + i] = t;
  }
}

function rotate(array, a, m, b) {
  var l = m - a,
    r = b - m;
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

// Selects the c smallest combined elements of the two already-sorted runs
// [a, m) and [m, b) into the front half via a single rotation. Uses a
// merge-path (co-rank) binary search over whichever run is shorter: it
// looks for the split count r such that taking r elements from the tail of
// one run and (c - r) from the head of the other yields exactly the c
// smallest values in order, rather than searching for a value directly.
function partitionMerge(array, a, m, b, c) {
  var lenA = m - a,
    lenB = b - m;
  if (lenA < 1 || lenB < 1) return;

  var r1, r2, ml;
  if (lenB < lenA) {
    var cc = lenA + lenB - c;
    r1 = Math.max(0, cc - lenA);
    r2 = Math.min(cc, lenB);
    while (r1 < r2) {
      ml = r1 + Math.floor((r2 - r1) / 2);
      if (array[m - (cc - ml)] > array[b - ml - 1]) {
        r2 = ml;
      } else {
        r1 = ml + 1;
      }
    }
    rotate(array, m - (cc - r1), m, b - r1);
  } else {
    r1 = Math.max(0, c - lenB);
    r2 = Math.min(c, lenA);
    while (r1 < r2) {
      ml = r1 + Math.floor((r2 - r1) / 2);
      if (array[a + ml] > array[m + (c - ml) - 1]) {
        r2 = ml;
      } else {
        r1 = ml + 1;
      }
    }
    rotate(array, a + r1, m, m + (c - r1));
  }
}

// Finds the first place inside [a, b) where ascending order breaks, then
// partition-merges the sorted piece before it with the sorted piece after
// it. A no-op if [a, b) is already one ascending run.
function rotateMerge(array, a, b, c) {
  var i = a + 1;
  while (i < b && array[i - 1] <= array[i]) i++;
  if (i < b) partitionMerge(array, a, i, b, c);
}

function rotatePartitionMergeSort(array, n) {
  if (n < 2) return;

  for (var i = 1; i < n; i += 2) {
    if (array[i - 1] > array[i]) {
      var t = array[i - 1];
      array[i - 1] = array[i];
      array[i] = t;
    }
  }

  for (var j = 2; j < n; j *= 2) {
    var b1 = 0;
    var blockStart = 0;
    while (blockStart + j < n) {
      b1 = Math.min(blockStart + 2 * j, n);
      partitionMerge(array, blockStart, blockStart + j, b1, j);
      blockStart += 2 * j;
    }

    for (var k = j / 2; k > 1; k /= 2) {
      var seamStart = 0;
      while (seamStart + k < b1) {
        var seamEnd = Math.min(seamStart + 2 * k, n);
        rotateMerge(array, seamStart, seamEnd, k);
        seamStart += 2 * k;
      }
    }

    for (var m = 1; m < b1; m += 2) {
      if (array[m - 1] > array[m]) {
        var t2 = array[m - 1];
        array[m - 1] = array[m];
        array[m] = t2;
      }
    }
  }
}

function sort(arr) {
  rotatePartitionMergeSort(arr, arr.length);
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
