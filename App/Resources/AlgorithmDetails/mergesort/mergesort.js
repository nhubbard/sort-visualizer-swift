function sort(array) {
  const scratch = new Array(array.length);

  function merge(start, mid, end) {
    let left = start;
    let right = mid;
    let out = start;
    while (left < mid && right < end) {
      if (array[left] <= array[right]) {
        scratch[out++] = array[left++];
      } else {
        scratch[out++] = array[right++];
      }
    }
    while (left < mid) scratch[out++] = array[left++];
    while (right < end) scratch[out++] = array[right++];
    for (let i = start; i < end; i++) array[i] = scratch[i];
  }

  function mergeSort(start, end) {
    if (end - start < 2) return;
    const mid = start + Math.floor((end - start) / 2);
    mergeSort(start, mid);
    mergeSort(mid, end);
    merge(start, mid, end);
  }

  mergeSort(0, array.length);
  return array;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
