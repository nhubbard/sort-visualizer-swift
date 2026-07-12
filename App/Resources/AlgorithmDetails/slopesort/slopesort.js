function sort(arr) {
  const n = arr.length;
  for (let start = 1; start < n; start++) {
    let i = start;
    let k = start - 1;
    while (k >= 0) {
      if (arr[i] < arr[k]) {
        [arr[i], arr[k]] = [arr[k], arr[i]];
      }
      k--;
      i--;
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");