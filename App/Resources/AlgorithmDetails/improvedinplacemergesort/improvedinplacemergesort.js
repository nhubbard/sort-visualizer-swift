function push(array, p, a, b) {
  if (a === b) {
    return;
  }
  var temp = array[p];
  array[p] = array[a];
  for (var i = a + 1; i < b; i++) {
    array[i - 1] = array[i];
  }
  array[b - 1] = temp;
}

function merge(array, a, m, b) {
  var i = a;
  var j = m;
  while (i < m && j < b) {
    if (array[i] > array[j]) {
      j++;
    } else {
      push(array, i, m, j);
      i++;
    }
  }
  while (i < m) {
    push(array, i, m, b);
    i++;
  }
}

function mergeSort(array, a, b) {
  var m = a + Math.floor((b - a) / 2);
  if (b - a > 2) {
    if (b - a > 3) {
      mergeSort(array, a, m);
    }
    mergeSort(array, m, b);
  }
  merge(array, a, m, b);
}

function sort(arr) {
  const n = arr.length;
  mergeSort(arr, 0, n);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
