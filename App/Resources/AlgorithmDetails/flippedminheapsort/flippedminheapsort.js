function sort(arr) {
  const n = arr.length;

  function idx(p) {
    return n - p;
  }

  function siftDown(root, dist) {
    while (root <= Math.floor(dist / 2)) {
      let leaf = 2 * root;
      if (leaf < dist && arr[idx(leaf)] > arr[idx(leaf + 1)]) {
        leaf += 1;
      }
      if (arr[idx(root)] > arr[idx(leaf)]) {
        [arr[idx(root)], arr[idx(leaf)]] = [arr[idx(leaf)], arr[idx(root)]];
        root = leaf;
      } else {
        break;
      }
    }
  }

  let i = Math.floor(n / 2);
  while (i >= 1) {
    siftDown(i, n);
    i -= 1;
  }

  i = n;
  while (i > 1) {
    [arr[idx(1)], arr[idx(i)]] = [arr[idx(i)], arr[idx(1)]];
    siftDown(1, i - 1);
    i -= 1;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
