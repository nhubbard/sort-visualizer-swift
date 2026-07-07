function sort(arr) {
  var n = arr.length;
  var max = arr[0];
  for (var i = 1; i < n; i++) {
    if (arr[i] > max) max = arr[i];
  }

  var counts = new Array(max + 1).fill(0);
  for (var i = 0; i < n; i++) {
    counts[arr[i]]++;
  }
  for (var i = 1; i <= max; i++) {
    counts[i] += counts[i - 1];
  }

  var output = new Array(n);
  for (var i = n - 1; i >= 0; i--) {
    counts[arr[i]]--;
    output[counts[arr[i]]] = arr[i];
  }

  for (var i = 0; i < n; i++) {
    arr[i] = output[i];
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
