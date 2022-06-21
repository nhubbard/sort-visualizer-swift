function heapSort(array) {
  let size = array.length;
  for (let i = Math.floor(size / 2 - 1); i >= 0; i--) {
    heapify(array, size, i);
  }
  for (let i = size - 1; i >= 0; i--) {
    [array[0], array[i]] = [array[i], array[0]];
    heapify(array, i, 0);
  }
}

function heapify(array, size, i) {
  let max = i;
  let left = 2 * i + 1;
  let right = 2 * i + 2;
  if (left < size && array[left] > array[max]) {
    max = left;
  }
  if (right < size && array[right] > array[max]) {
    max = right;
  }
  if (max != i) {
    [array[i], array[max]] = [array[max], array[i]];
    heapify(array, size, max);
  }
}

var array = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0];
heapSort(array);
console.log(array);
