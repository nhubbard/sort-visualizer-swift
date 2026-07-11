function isMinimum(arr, start, end) {
  for (let k = start + 1; k < end; k++)
    if (arr[start] > arr[k])
      return false;
  return true;
}

function shuffleRange(arr, start, end) {
  for (let i = start; i < end - 1; i++) {
    const j = i + Math.floor(Math.random() * (end - i));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
}

function sort(arr) {
  const n = arr.length;
  for (let i = 0; i < n; i++)
    while (!isMinimum(arr, i, n))
      shuffleRange(arr, i, n);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
