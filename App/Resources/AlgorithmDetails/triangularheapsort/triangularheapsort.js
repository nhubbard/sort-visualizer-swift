function triangularRoot(val) {
  return ((Math.floor(Math.sqrt(8 * val + 1)) - 1) / 2) | 0;
}

function siftDown(array, root, size) {
  while (true) {
    const row = triangularRoot(root);
    const left = root + row + 1;
    if (left >= size) break;
    const right = left + 1;
    let largest = root;
    if (array[largest] < array[left]) largest = left;
    if (right < size && array[largest] < array[right]) largest = right;
    if (largest === root) break;
    [array[root], array[largest]] = [array[largest], array[root]];
    root = largest;
  }
}

function heapify(array, length) {
  for (let i = length - 1; i >= 0; i--) {
    siftDown(array, i, length);
  }
}

function sort(array) {
  const n = array.length;
  if (n <= 1) return;
  heapify(array, n);
  for (let i = 1; i < n - 1; i++) {
    [array[0], array[n - i]] = [array[n - i], array[0]];
    siftDown(array, 0, n - i);
  }
  if (array[0] > array[1]) {
    [array[0], array[1]] = [array[1], array[0]];
  }
}

const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log(`[${array.join(", ")}]`);
