function sort(array) {
  var n = array.length;
  var i = 0;
  while (i < Math.floor(n / 2)) {
    var sorted = true;
    for (var j = i; j < n - i - 1; j++) {
      if (array[j] > array[j + 1]) {
        [array[j], array[j + 1]] = [array[j + 1], array[j]];
        sorted = false;
      }
    }
    for (var j = n - i - 1; j > i; j--) {
      if (array[j] < array[j - 1]) {
        [array[j], array[j - 1]] = [array[j - 1], array[j]];
        sorted = false;
      }
    }
    if (sorted) {
      break;
    }
    i++;
  }
  return array;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
