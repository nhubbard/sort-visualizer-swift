function siftDown(arr, root, size) {
  while (true) {
    var smallest = root;
    var left = 2 * root + 1;
    var right = 2 * root + 2;
    if (left < size && arr[left] < arr[smallest]) {
      smallest = left;
    }
    if (right < size && arr[right] < arr[smallest]) {
      smallest = right;
    }
    if (smallest === root) {
      break;
    }
    [arr[root], arr[smallest]] = [arr[smallest], arr[root]];
    root = smallest;
  }
}

function heapify(arr) {
  for (var i = Math.floor(arr.length / 2) - 1; i >= 0; i--) {
    siftDown(arr, i, arr.length);
  }
}

function sort(arr) {
  heapify(arr);
  for (var end = arr.length - 1; end > 0; end--) {
    [arr[0], arr[end]] = [arr[end], arr[0]];
    siftDown(arr, 0, end);
  }
  arr.reverse();
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
