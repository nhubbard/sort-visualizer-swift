function sort(arr) {
  let n = arr.length;
  for (let c = 0; c < n - 1; c++) {
    for (let d = 0; d < n - c - 1; d++) {
      if (arr[d] > arr[d + 1]) {
        [arr[d], arr[d + 1]] = [arr[d + 1], arr[d]];
      }
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");