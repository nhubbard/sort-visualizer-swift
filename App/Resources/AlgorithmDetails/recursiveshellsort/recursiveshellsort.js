function sort(arr) {
  recursiveShellSort(arr, 0, arr.length, 1);
}

function gappedInsertionSort(array, a, b, gap) {
  for (let i = a + gap; i < b; i += gap) {
    let j = i;
    while (j - gap >= a && array[j] < array[j - gap]) {
      [array[j], array[j - gap]] = [array[j - gap], array[j]];
      j -= gap;
    }
  }
}

function recursiveShellSort(array, start, end, g) {
  if (start + g <= end) {
    recursiveShellSort(array, start, end, 3 * g);
    recursiveShellSort(array, start + g, end, 3 * g);
    recursiveShellSort(array, start + 2 * g, end, 3 * g);
    gappedInsertionSort(array, start, end, g);
  }
}


const array = [
  0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
];
sort(array);
console.log("[" + array.join(", ") + "]");
