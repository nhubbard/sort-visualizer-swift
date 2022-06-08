function gnomeSort(arr) {
  const n = arr.length;
  let index = 0;
  while (index < n) {
    if (index == 0) {
      index++;
    }
    if (arr[index] >= arr[index - 1]) {
      index++;
    } else {
      let swapTemp = arr[index];
      arr[index] = arr[index - 1];
      arr[index - 1] = swapTemp;
      index--;
    }
  }
}

var array = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0];
gnomeSort(array);
console.log(array);