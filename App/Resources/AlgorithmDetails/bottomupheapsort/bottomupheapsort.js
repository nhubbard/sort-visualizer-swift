function sort(arr) {
  const n = arr.length;

  function siftDown(i, b) {
    let j = i;
    while (2 * j + 1 < b) {
      if (2 * j + 2 < b) {
        j = arr[2 * j + 2] > arr[2 * j + 1] ? 2 * j + 2 : 2 * j + 1;
      } else {
        j = 2 * j + 1;
      }
    }
    while (arr[i] > arr[j]) {
      j = Math.floor((j - 1) / 2);
    }
    while (j > i) {
      [arr[i], arr[j]] = [arr[j], arr[i]];
      j = Math.floor((j - 1) / 2);
    }
  }

  for (let i = Math.floor((n - 1) / 2); i >= 0; i--) {
    siftDown(i, n);
  }

  for (let i = n - 1; i > 0; i--) {
    [arr[0], arr[i]] = [arr[i], arr[0]];
    siftDown(0, i);
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
