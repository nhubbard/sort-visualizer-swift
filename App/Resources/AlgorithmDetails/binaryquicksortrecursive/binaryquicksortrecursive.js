function mostSignificantBit(value) {
  if (value === 0) return -1;
  let bit = 0;
  while (value >> (bit + 1) !== 0) bit++;
  return bit;
}

function partition(arr, p, r, bit) {
  let i = p - 1;
  let j = r + 1;
  while (true) {
    do {
      i++;
    } while (i <= r && ((arr[i] >> bit) & 1) === 0);
    do {
      j--;
    } while (j >= p && ((arr[j] >> bit) & 1) === 1);
    if (i < j) {
      [arr[i], arr[j]] = [arr[j], arr[i]];
    } else {
      return j;
    }
  }
}

function binaryQuickSortRecursive(arr, p, r, bit) {
  if (p < r && bit >= 0) {
    const q = partition(arr, p, r, bit);
    binaryQuickSortRecursive(arr, p, q, bit - 1);
    binaryQuickSortRecursive(arr, q + 1, r, bit - 1);
  }
}

function sort(arr) {
  const n = arr.length;
  let maxValue = arr[0];
  for (let i = 1; i < n; i++) {
    if (arr[i] > maxValue) maxValue = arr[i];
  }
  const bit = mostSignificantBit(maxValue);
  binaryQuickSortRecursive(arr, 0, n - 1, bit);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
