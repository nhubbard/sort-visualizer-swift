function sort(values) {
  const n = values.length;
  if (n < 2) return;
  const scratch = [...values];
  const buffer = [...scratch];
  function mergeSort(lo, hi) {
    if (hi - lo < 2) return;
    const mid = lo + Math.floor((hi - lo) / 2);
    mergeSort(lo, mid);
    mergeSort(mid, hi);
    let left = lo,
      right = mid,
      dest = lo;
    while (left < mid && right < hi) {
      buffer[dest++] =
        scratch[left] <= scratch[right] ? scratch[left++] : scratch[right++];
    }
    while (left < mid) buffer[dest++] = scratch[left++];
    while (right < hi) buffer[dest++] = scratch[right++];
    for (let i = lo; i < hi; i++) scratch[i] = buffer[i];
  }
  mergeSort(0, n);
  for (let i = 0; i < n; i++) values[i] = scratch[i];
  for (let i = 1; i < n; i++) {
    let j = i;
    while (j > 0 && values[j - 1] > values[j]) {
      [values[j - 1], values[j]] = [values[j], values[j - 1]];
      j--;
    }
  }
}
const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
