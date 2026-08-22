function sort(arr) {
  const n = arr.length;
  if (n <= 1) {
    return;
  }
  const pow2 = Math.trunc(Math.log(n - 1) / Math.log(2));
  for (let k = pow2; k >= 0; k--) {
    const pow3 = Math.trunc((Math.log(n) - k * Math.log(2)) / Math.log(3));
    for (let j = pow3; j >= 0; j--) {
      const gap = Math.trunc(Math.pow(2, k) * Math.pow(3, j));
      for (let i = 0; i + gap < n; i++) {
        if (arr[i] > arr[i + gap]) {
          const t = arr[i];
          arr[i] = arr[i + gap];
          arr[i + gap] = t;
        }
      }
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
