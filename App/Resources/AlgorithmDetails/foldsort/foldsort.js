function compSwap(arr, a, b, end) {
  if (b < end && arr[a] > arr[b]) {
    var temp = arr[a];
    arr[a] = arr[b];
    arr[b] = temp;
  }
}

function halver(arr, low, high, end) {
  while (low < high) {
    compSwap(arr, low, high, end);
    low++;
    high--;
  }
}

function sort(arr) {
  const n = arr.length;
  let ceilLog = 1;
  while (1 << ceilLog < n) {
    ceilLog++;
  }
  const end = n;
  const size2 = 1 << ceilLog;

  let k = size2 >> 1;
  while (k > 0) {
    let i = size2;
    while (i >= k) {
      let j = 0;
      while (j < end) {
        halver(arr, j, j + i - 1, end);
        j += i;
      }
      i >>= 1;
    }
    k >>= 1;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
