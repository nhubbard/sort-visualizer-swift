function isSorted(arr) {
  for (let i = 1; i < arr.length; i++)
    if (arr[i - 1] > arr[i])
      return false;
  return true;
}

function sort(arr) {
  const n = arr.length;
  while (!isSorted(arr)) {
    const index = Math.floor(Math.random() * (n - 1));
    if (arr[index] > arr[index + 1]) {
      [arr[index], arr[index + 1]] = [arr[index + 1], arr[index]];
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
