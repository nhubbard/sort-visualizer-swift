function sort(arr) {
  const scratch = new Array(arr.length);

  function mergeSort(start, end) {
    if (end - start < 2) return;
    const middle = Math.floor((start + end) / 2);
    mergeSort(start, middle);
    mergeSort(middle, end);
    let left = start,
      right = middle,
      dest = start;
    while (left < middle && right < end) {
      scratch[dest++] = arr[left] <= arr[right] ? arr[left++] : arr[right++];
    }
    while (left < middle) scratch[dest++] = arr[left++];
    while (right < end) scratch[dest++] = arr[right++];
    for (let i = start; i < end; i++) arr[i] = scratch[i];
  }

  let start = 0,
    end = arr.length;
  while (end - start > 16) {
    const samples = [
      arr[start],
      arr[Math.floor((start + end - 1) / 2)],
      arr[end - 1],
    ];
    samples.sort((a, b) => a - b);
    const pivot = samples[1];
    let left = start,
      right = end - 1;
    while (left <= right) {
      while (left <= right && arr[left] < pivot) left++;
      while (left <= right && arr[right] > pivot) right--;
      if (left <= right) {
        [arr[left], arr[right]] = [arr[right], arr[left]];
        left++;
        right--;
      }
    }
    if (left === start || left === end) {
      mergeSort(start, end);
      return;
    }
    if (left - start <= end - left) {
      mergeSort(start, left);
      start = left;
    } else {
      mergeSort(left, end);
      end = left;
    }
  }
  for (let i = start + 1; i < end; i++) {
    const value = arr[i];
    let j = i;
    while (j > start && arr[j - 1] > value) arr[j] = arr[--j];
    arr[j] = value;
  }
}

const array = [
  0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56, 10, 2, 95, 46,
  21, 74, 6, 38,
];
sort(array);
console.log("[" + array.join(", ") + "]");
