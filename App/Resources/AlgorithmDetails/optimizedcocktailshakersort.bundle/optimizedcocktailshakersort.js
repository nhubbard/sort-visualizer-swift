function sort(arr) {
  var start = 0;
  var end = arr.length - 1;
  while (start < end) {
    var consecSorted = 1;
    for (var i = start; i < end; i++) {
      if (arr[i] > arr[i + 1]) {
        [arr[i], arr[i + 1]] = [arr[i + 1], arr[i]];
        consecSorted = 1;
      } else {
        consecSorted++;
      }
    }
    end -= consecSorted;

    consecSorted = 1;
    for (var j = end; j > start; j--) {
      if (arr[j - 1] > arr[j]) {
        [arr[j - 1], arr[j]] = [arr[j], arr[j - 1]];
        consecSorted = 1;
      } else {
        consecSorted++;
      }
    }
    start += consecSorted;
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
