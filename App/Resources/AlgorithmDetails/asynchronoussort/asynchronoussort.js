function sort(arr) {
  const n = arr.length;
  const ext = [...arr];
  let minValue = ext[0];
  let maxValue = ext[0];
  for (let k = 0; k < n; k++) {
    if (ext[k] < minValue) minValue = ext[k];
    if (ext[k] > maxValue) maxValue = ext[k];
  }
  maxValue += 1;

  let cur = minValue;
  let i = 0;
  while (i < n) {
    for (let j = 0; j < n; j++) {
      if (ext[j] <= cur) {
        arr[i] = ext[j];
        ext[j] = maxValue;
        i += 1;
      }
    }
    cur += 1;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
