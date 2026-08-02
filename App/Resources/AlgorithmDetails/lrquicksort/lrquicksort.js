function quickSort(array, p, r) {
  if (p >= r) {
    return;
  }

  var pivot = array[p + Math.floor((r - p + 1) / 2)];
  var i = p;
  var j = r;

  while (i <= j) {
    while (array[i] < pivot) {
      i++;
    }
    while (array[j] > pivot) {
      j--;
    }
    if (i <= j) {
      [array[i], array[j]] = [array[j], array[i]];
      i++;
      j--;
    }
  }

  if (p < j) {
    quickSort(array, p, j);
  }
  if (i < r) {
    quickSort(array, i, r);
  }
}

function sort(arr) {
  quickSort(arr, 0, arr.length - 1);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
