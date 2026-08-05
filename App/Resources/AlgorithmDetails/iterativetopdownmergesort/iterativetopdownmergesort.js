function merge(array, low, mid, high) {
  var left = array.slice(low, mid);
  var right = array.slice(mid, high);
  var i = 0,
    j = 0,
    k = low;
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
  var subarrayCount = 1;
  while (subarrayCount < n) {
    subarrayCount *= 2;
  }

  while (subarrayCount > 1) {
    for (var i = 0; i < subarrayCount; i += 2) {
      var low = Math.floor((n * i) / subarrayCount);
      var mid = Math.floor((n * (i + 1)) / subarrayCount);
      var high = Math.floor((n * (i + 2)) / subarrayCount);
      merge(arr, low, mid, high);
    }
    subarrayCount = Math.floor(subarrayCount / 2);
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
