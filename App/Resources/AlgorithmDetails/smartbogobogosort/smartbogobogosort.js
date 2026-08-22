function sort(arr, length = arr.length) {
  if (length === 1) {
    return;
  }
  sort(arr, length - 1);
  while (arr[length - 2] > arr[length - 1]) {
    for (let i = length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const temp = arr[i];
      arr[i] = arr[j];
      arr[j] = temp;
    }
    sort(arr, length - 1);
  }
}

var array = [0, 39, 21, 62, 91, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
