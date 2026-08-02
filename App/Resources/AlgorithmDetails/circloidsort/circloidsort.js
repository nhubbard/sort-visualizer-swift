function circle(array, left, right) {
  var a = left;
  var b = right;
  var swapped = false;
  while (a < b) {
    if (array[a] > array[b]) {
      var t = array[a];
      array[a] = array[b];
      array[b] = t;
      swapped = true;
    }
    a++;
    b--;
    if (a === b) {
      b++;
    }
  }
  return swapped;
}

function circlePass(array, left, right) {
  if (left >= right) {
    return false;
  }
  var mid = Math.floor((left + right) / 2);
  var l = circlePass(array, left, mid);
  var r = circlePass(array, mid + 1, right);
  return circle(array, left, right) || l || r;
}

function sort(arr) {
  const n = arr.length;
  if (n <= 1) {
    return;
  }
  while (circlePass(arr, 0, n - 1)) {
    // repeat until a full sweep makes no swaps
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
