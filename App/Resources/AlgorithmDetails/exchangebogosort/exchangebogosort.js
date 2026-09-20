function sort(arr) {
  const n = arr.length;
  while (!isSorted(arr)) {
    const i = Math.floor(Math.random() * n);
    const j = Math.floor(Math.random() * n);
    if ((i < j && arr[i] > arr[j]) || (i > j && arr[i] < arr[j])) {
      [arr[i], arr[j]] = [arr[j], arr[i]];
    }
  }
}

function isSorted(arr) {
  for (let i = 1; i < arr.length; i++) if (arr[i - 1] > arr[i]) return false;
  return true;
}


const array = [
  0, 39, 21, 62, 91, 77, 14, 23,
];
sort(array);
console.log("[" + array.join(", ") + "]");
