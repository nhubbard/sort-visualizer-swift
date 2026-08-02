function sort(arr) {
  const n = arr.length;
  let minValue = arr[0];
  for (let i = 1; i < n; i++) {
    if (arr[i] < minValue) minValue = arr[i];
  }

  for (let i = 0; i < n; i++) {
    let cmpCount = 0;
    while (arr[i] - minValue !== i && cmpCount < n) {
      const j = arr[i] - minValue;
      const temp = arr[i];
      arr[i] = arr[j];
      arr[j] = temp;
      cmpCount++;
    }
    if (cmpCount >= n - 1) break;
  }
}

var array = [7, 3, 14, 0, 9, 5, 12, 1, 15, 4, 10, 2, 13, 6, 11, 8];
sort(array);
console.log("[" + array.join(", ") + "]");
