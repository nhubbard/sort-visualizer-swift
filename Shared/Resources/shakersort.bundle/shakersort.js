function shakerSort(arr) {
  const n = arr.length;
  let swapped = true;
  let start = 0;
  let end = n - 1;
  while (swapped) {
    swapped = false;
    for (let i = start; i < end; i++) {
      if (arr[i] > arr[i + 1]) {
        let temp = arr[i];
        arr[i] = arr[i + 1];
        arr[i + 1] = temp;
        swapped = true;
      }
    }
    if (!swapped) {
      break;
    }
    swapped = false;
    end--;
    for (let i = end - 1; i >= start; i--) {
      if (arr[i] > arr[i + 1]) {
        let temp = arr[i];
        arr[i] = arr[i + 1];
        arr[i + 1] = temp;
        swapped = true;
      }
    }
    start++;
  }
}

var array = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0];
shakerSort(array);
console.log(array);