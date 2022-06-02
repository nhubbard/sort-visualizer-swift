function heapSort(array) {
  let size = array.length;
  for (let i = Math.floor(size / 2 - 1); i >= 0; i--) {
    heapify(array, size, i);
  }
  for (let i = size - 1; i >= 0; i--) {
    let temp = array[0];
    array[0] = array[i];
    array[i] = temp;
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
    let temp = array[i];
    array[i] = array[max];
    array[max] = temp;
    heapify(array, size, max);
  }
}

var array = [1, 5, 2, 3, 7, 4, 8, 9];
heapSort(array);
console.log(array);