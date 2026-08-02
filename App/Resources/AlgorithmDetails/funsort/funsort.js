function compositeLess(arr, key, mid, i) {
  if (arr[mid] < arr[i]) return true;
  if (arr[mid] === arr[i]) return key[mid] < key[i];
  return false;
}

function binarySearch(arr, key, n, i) {
  let start = 0;
  let end = n - 1;
  while (start < end) {
    const mid = Math.floor((start + end) / 2);
    if (compositeLess(arr, key, mid, i)) {
      start = mid + 1;
    } else {
      end = mid;
    }
  }
  return start;
}

function sort(arr) {
  const n = arr.length;
  const key = [];
  for (let i = 0; i < n; i++) key[i] = i;

  for (let i = 1; i < n; i++) {
    let done = false;
    while (!done) {
      const pos = binarySearch(arr, key, n, i);
      if (pos === i) {
        done = true;
      } else if (i < pos - 1) {
        [arr[i], arr[pos - 1]] = [arr[pos - 1], arr[i]];
        [key[i], key[pos - 1]] = [key[pos - 1], key[i]];
      } else {
        [arr[i], arr[pos]] = [arr[pos], arr[i]];
        [key[i], key[pos]] = [key[pos], key[i]];
      }
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
