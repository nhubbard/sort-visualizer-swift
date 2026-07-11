const BASE = 4;

function siftDown(arr, node, stop) {
  const left = node * BASE + 1;
  if (left >= stop) {
    return;
  }
  let maxIndex = left;
  for (let i = left + 1; i < left + BASE && i < stop; i++) {
    if (arr[maxIndex] < arr[i]) {
      maxIndex = i;
    }
  }
  if (arr[node] < arr[maxIndex]) {
    [arr[node], arr[maxIndex]] = [arr[maxIndex], arr[node]];
    siftDown(arr, maxIndex, stop);
  }
}

function sort(arr) {
  const n = arr.length;
  for (let i = n - 1; i >= 0; i--) {
    siftDown(arr, i, n);
  }
  for (let end = n - 1; end > 0; end--) {
    [arr[0], arr[end]] = [arr[end], arr[0]];
    siftDown(arr, 0, end);
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
