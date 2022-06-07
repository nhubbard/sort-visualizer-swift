function bubbleSort(arr, n) {
  for (let c = 0; c < n - 1; c++) {
    for (let d = 0; d < n - c - 1; d++) {
      if (arr[d] > arr[d + 1]) {
        let temp = arr[d];
        arr[d] = arr[d + 1];
        arr[d + 1] = temp;
      }
    }
  }
}

var array = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0];
bubbleSort(array, array.length - 1);
console.log(array);