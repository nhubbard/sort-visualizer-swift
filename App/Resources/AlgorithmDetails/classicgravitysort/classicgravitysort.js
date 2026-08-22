function sort(arr) {
  const n = arr.length;
  if (n === 0) return arr;

  let maxValue = arr[0];
  for (let i = 1; i < n; i++) {
    if (arr[i] > maxValue) maxValue = arr[i];
  }

  const transpose = new Array(maxValue).fill(0);

  for (let i = 0; i < n; i++) {
    const value = arr[i];
    for (let j = 0; j < value; j++) {
      transpose[j]++;
    }
  }

  for (let i = 0; i < n; i++) {
    let total = 0;
    for (let j = 0; j < maxValue; j++) {
      if (transpose[j] > 0) total++;
    }
    arr[n - i - 1] = total;
    for (let j = 0; j < maxValue; j++) {
      transpose[j]--;
    }
  }

  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
