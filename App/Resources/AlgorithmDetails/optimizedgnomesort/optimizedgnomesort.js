function sort(arr) {
  for (var i = 1; i < arr.length; i++) {
    var pos = i;
    while (pos > 0 && arr[pos - 1] > arr[pos]) {
      [arr[pos - 1], arr[pos]] = [arr[pos], arr[pos - 1]];
      pos--;
    }
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
