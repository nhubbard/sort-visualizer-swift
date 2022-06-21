function selectionSort(arr) {
  let n = array.length;
  for (let i = 0; i < n - 1; i++) {
    let minIdx = i;
    for (let j = i + 1; j < n; j++) {
      if (arr[j] < arr[minIdx]) {
        minIdx = j;
      }
    }
    [arr[minIdx], arr[i]] = [arr[i], arr[minIdx]];
  }
}

var array = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0];
selectionSort(array);
console.log(array);
