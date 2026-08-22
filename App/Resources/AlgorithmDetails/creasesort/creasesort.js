function compSwap(arr, a, b) {
  if (arr[a] > arr[b]) {
    const temp = arr[a];
    arr[a] = arr[b];
    arr[b] = temp;
  }
}

function sort(arr) {
  const n = arr.length;
  let maxVal = 1;
  while (maxVal * 2 < n) {
    maxVal *= 2;
  }

  let next = maxVal;
  while (next > 0) {
    let i = 0;
    while (i + 1 < n) {
      compSwap(arr, i, i + 1);
      i += 2;
    }

    let j = maxVal;
    while (j >= next && j > 1) {
      i = 1;
      while (i + j - 1 < n) {
        compSwap(arr, i, i + j - 1);
        i += 2;
      }
      j = Math.floor(j / 2);
    }

    next = Math.floor(next / 2);
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
