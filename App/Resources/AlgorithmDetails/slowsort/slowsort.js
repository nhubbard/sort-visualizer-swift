function slowSort(array, i, j) {
  if (i >= j) {
    return;
  }
  var m = i + Math.floor((j - i) / 2);
  slowSort(array, i, m);
  slowSort(array, m + 1, j);
  if (array[m] > array[j]) {
    [array[m], array[j]] = [array[j], array[m]];
  }
  slowSort(array, i, j - 1);
}

function sort(arr) {
  slowSort(arr, 0, arr.length - 1);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
