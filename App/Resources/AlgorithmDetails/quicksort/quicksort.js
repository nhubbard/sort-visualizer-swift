function sort(arr) {
  quickSort(arr, 0, arr.length - 1);
}

function quickSort(array, start, end) {
  if (start >= end) return;
  let i = start;
  let j = end;
  while (i < j) {
    while (i < j && array[i] <= array[start]) i++;
    while (array[j] > array[start]) j--;
    if (i < j) [array[i], array[j]] = [array[j], array[i]];
  }
  [array[start], array[j]] = [array[j], array[start]];
  quickSort(array, start, j - 1);
  quickSort(array, j + 1, end);
}


const array = [
  0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
];
sort(array);
console.log("[" + array.join(", ") + "]");
