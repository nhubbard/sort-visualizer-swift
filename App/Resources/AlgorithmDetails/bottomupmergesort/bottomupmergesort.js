function merge(array, scratch, n, index, mergeSize) {
  const mid = index + Math.floor(mergeSize / 2);
  const end = Math.min(n, index + mergeSize);
  if (mid >= end) return index;
  let left = index, right = mid, out = index;
  while (left < mid && right < end)
    scratch[out++] = array[left] <= array[right] ? array[left++] : array[right++];
  while (left < mid) scratch[out++] = array[left++];
  while (right < end) scratch[out++] = array[right++];
  return -1;
}

function sort(arr) {
  const n = arr.length;
  if (n < 2) return;
  const scratch = arr.slice();
  let mergeSize = 2;
  while (mergeSize <= n) {
    let copyLength = n;
    for (let index = 0; index < n; index += mergeSize) {
      const stop = merge(arr, scratch, n, index, mergeSize);
      if (stop >= 0) copyLength = stop;
    }
    for (let j = 0; j < copyLength; j++) arr[j] = scratch[j];
    mergeSize *= 2;
  }
  if (Math.floor(mergeSize / 2) !== n) {
    const stop = merge(arr, scratch, n, 0, mergeSize);
    const copyLength = stop < 0 ? n : stop;
    for (let j = 0; j < copyLength; j++) arr[j] = scratch[j];
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
