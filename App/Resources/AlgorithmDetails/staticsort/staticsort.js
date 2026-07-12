function findMinMax(array, a, b) {
  var minValue = array[a];
  var maxValue = minValue;
  for (var i = a + 1; i < b; i++) {
    if (array[i] < minValue) {
      minValue = array[i];
    } else if (array[i] > maxValue) {
      maxValue = array[i];
    }
  }
  return [minValue, maxValue];
}

function insertionSortRange(array, s, e) {
  for (var i = s + 1; i < e; i++) {
    var j = i;
    while (j > s && array[j - 1] > array[j]) {
      var tmp = array[j - 1];
      array[j - 1] = array[j];
      array[j] = tmp;
      j -= 1;
    }
  }
}

function siftDown(array, s, root, size) {
  while (true) {
    var largest = root;
    var left = 2 * root + 1;
    var right = 2 * root + 2;
    if (left < size && array[s + largest] < array[s + left]) {
      largest = left;
    }
    if (right < size && array[s + largest] < array[s + right]) {
      largest = right;
    }
    if (largest === root) break;
    var tmp = array[s + root];
    array[s + root] = array[s + largest];
    array[s + largest] = tmp;
    root = largest;
  }
}

function heapSortRange(array, s, e) {
  var size = e - s;
  if (size <= 1) return;
  var i = Math.trunc(size / 2) - 1;
  while (i >= 0) {
    siftDown(array, s, i, size);
    i -= 1;
  }
  var end = size - 1;
  while (end > 0) {
    var tmp = array[s];
    array[s] = array[s + end];
    array[s + end] = tmp;
    siftDown(array, s, 0, end);
    end -= 1;
  }
}

function staticSort(array, a, b) {
  var minMax = findMinMax(array, a, b);
  var minValue = minMax[0];
  var maxValue = minMax[1];
  var auxLen = b - a;
  var count = new Array(auxLen + 1).fill(0);
  var offset = new Array(auxLen + 1).fill(0);
  var CONST = auxLen / (maxValue - minValue + 1);

  function classify(value) {
    return Math.trunc((value - minValue) * CONST);
  }

  for (var i = a; i < b; i++) {
    var idx = classify(array[i]);
    count[idx] += 1;
  }

  offset[0] = a;
  for (var k = 1; k < auxLen; k++) {
    offset[k] = count[k - 1] + offset[k - 1];
  }

  for (var v = 0; v < auxLen; v++) {
    while (count[v] > 0) {
      var origin = offset[v];
      var from = origin;
      var num = array[from];
      array[from] = -1;
      do {
        var idx2 = classify(num);
        var to = offset[idx2];
        offset[idx2] += 1;
        count[idx2] -= 1;
        var temp = array[to];
        array[to] = num;
        num = temp;
        from = to;
      } while (from !== origin);
    }
  }

  for (var m = 0; m < auxLen; m++) {
    var s = m > 1 ? offset[m - 1] : a;
    var e = offset[m];
    if (e - s <= 1) continue;
    if (e - s > 16) {
      heapSortRange(array, s, e);
    } else {
      insertionSortRange(array, s, e);
    }
  }
}

function sort(arr) {
  if (arr.length > 1) {
    staticSort(arr, 0, arr.length);
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
