function sort(arr) {
  const n = arr.length;
  const maxValue = n === 0 ? 0 : Math.max(...arr);
  const output = new Array(n);
  let divisor = 1;
  while (true) {
    const counts = [0, 0, 0, 0];
    for (const value of arr) counts[Math.floor(value / divisor) % 4]++;
    for (let digit = 1; digit < 4; digit++) counts[digit] += counts[digit - 1];
    for (let i = n - 1; i >= 0; i--) {
      const digit = Math.floor(arr[i] / divisor) % 4;
      output[--counts[digit]] = arr[i];
    }
    for (let i = 0; i < n; i++) arr[i] = output[i];
    if (divisor > Math.floor(maxValue / 4)) break;
    divisor *= 4;
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
