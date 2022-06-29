function sort(arr, i, j) {
  const n = arr.length;
  if (j === undefined) j = array.length - 1;
  if (i === undefined) i = 0;
  if (arr[j] < arr[i]) {
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  if (j - i > 1) {
    let t = Math.floor((j - i + 1) / 3);
    sort(arr, i, j - t);
    sort(arr, i + t, j);
    sort(arr, i, j - t);
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
