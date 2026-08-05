function siftDown(arr, root, size) {
  let index = root;
  while (2 * index + 1 < size) {
    let child = 2 * index + 1;
    if (child + 1 < size && arr[child + 1] > arr[child]) child++;
    index = child;
  }
  const rootValue = arr[root];
  while (rootValue > arr[index]) {
    index = Math.floor((index - 1) / 2);
  }
  while (index !== root) {
    [arr[root], arr[index]] = [arr[index], arr[root]];
    index = Math.floor((index - 1) / 2);
  }
}

function heapify(arr, length) {
  for (let i = Math.floor((length - 1) / 2); i >= 0; i--) {
    siftDown(arr, i, length);
  }
}

function findNext(arr, size) {
  let hole = 0;
  let left = 1;
  let right = 2;
  while (right < size && !(arr[left] === -1 && arr[right] === -1)) {
    if (arr[left] === -1) {
      [arr[hole], arr[right]] = [arr[right], arr[hole]];
      hole = right;
    } else if (arr[right] === -1) {
      [arr[hole], arr[left]] = [arr[left], arr[hole]];
      hole = left;
    } else if (arr[right] > arr[left]) {
      [arr[hole], arr[right]] = [arr[right], arr[hole]];
      hole = right;
    } else {
      [arr[hole], arr[left]] = [arr[left], arr[hole]];
      hole = left;
    }
    left = 2 * hole + 1;
    right = left + 1;
  }
  if (left < size && arr[left] !== -1) {
    [arr[hole], arr[left]] = [arr[left], arr[hole]];
  }
}

function sort(arr) {
  const n = arr.length;
  const output = new Array(n).fill(0);
  if (n <= 1) {
    if (n === 1) output[0] = arr[0];
    return output;
  }
  heapify(arr, n);
  for (let i = n - 1; i >= 0; i--) {
    output[i] = arr[0];
    arr[0] = -1;
    findNext(arr, n);
  }
  return output;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
var output = sort(array);
console.log("[" + output.join(", ") + "]");
