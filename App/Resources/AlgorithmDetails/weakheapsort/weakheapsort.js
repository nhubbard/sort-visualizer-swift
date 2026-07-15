function merge(arr, flags, i, j) {
  if (arr[i] < arr[j]) {
    flags[j] = !flags[j];
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
}

function sort(arr) {
  const n = arr.length;
  const flags = new Array(n).fill(false);

  for (let i = n - 1; i > 0; i--) {
    let j = i;
    while ((j & 1) === (flags[j >> 1] ? 1 : 0)) {
      j >>= 1;
    }
    const gparent = j >> 1;
    merge(arr, flags, gparent, i);
  }

  for (let i = n - 1; i > 1; i--) {
    [arr[0], arr[i]] = [arr[i], arr[0]];
    let x = 1;
    while (true) {
      const y = 2 * x + (flags[x] ? 1 : 0);
      if (y >= i) {
        break;
      }
      x = y;
    }
    while (x > 0) {
      merge(arr, flags, 0, x);
      x >>= 1;
    }
  }
  [arr[0], arr[1]] = [arr[1], arr[0]];
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
