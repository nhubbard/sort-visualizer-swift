function sort(arr) {
  const n = arr.length;
  for (const gap of [8861, 3938, 1750, 701, 301, 132, 57, 23, 10, 4, 1]) {
    if (gap >= n) continue;
    for (let i = gap; i < n; i += 1) {
      for (let j = i; j >= gap && arr[j] < arr[j - gap]; j -= gap) {
        [arr[j], arr[j - gap]] = [arr[j - gap], arr[j]];
      }
    }
  }
}

const array = [
  0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
];
sort(array);
console.log("[" + array.join(", ") + "]");
