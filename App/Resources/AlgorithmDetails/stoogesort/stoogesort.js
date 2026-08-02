function stoogeSort(arr, i, j) {
  if (arr[j] < arr[i]) {
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  if (j - i > 1) {
    let t = Math.floor((j - i + 1) / 3);
    stoogeSort(arr, i, j - t);
    stoogeSort(arr, i + t, j);
    stoogeSort(arr, i, j - t);
  }
}

function sort(arr) {
  stoogeSort(arr, 0, arr.length - 1);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
