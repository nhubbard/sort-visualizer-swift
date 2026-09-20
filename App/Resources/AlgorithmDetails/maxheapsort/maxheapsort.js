function siftDown(array, root, size) {
  while (true) {
    let largest = root;
    const left = 2 * root + 1;
    const right = left + 1;
    if (left < size && array[largest] < array[left]) largest = left;
    if (right < size && array[largest] < array[right]) largest = right;
    if (largest === root) break;
    [array[root], array[largest]] = [array[largest], array[root]];
    root = largest;
  }
}

function sort(array) {
  let size = array.length;
  for (let i = Math.floor(size / 2 - 1); i >= 0; i--) {
    siftDown(array, i, size);
  }
  for (let i = size - 1; i > 0; i--) {
    [array[0], array[i]] = [array[i], array[0]];
    siftDown(array, 0, i);
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
