function merge(array, low, mid, high) {
  var left = array.slice(low, mid);
  var right = array.slice(mid, high);
  var i = 0, j = 0, k = low;
  while (i < left.length && j < right.length) {
    if (left[i] <= right[j]) {
      array[k] = left[i];
      i++;
    } else {
      array[k] = right[j];
      j++;
    }
    k++;
  }
  while (i < left.length) {
    array[k] = left[i];
    i++;
    k++;
  }
  while (j < right.length) {
    array[k] = right[j];
    j++;
    k++;
  }
}

function sort(arr) {
  var n = arr.length;
  for (var width = 1; width < n; width *= 2) {
    for (var low = 0; low < n; low += 2 * width) {
      var mid = Math.min(low + width, n);
      var high = Math.min(low + 2 * width, n);
      if (mid < high) {
        merge(arr, low, mid, high);
      }
    }
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
