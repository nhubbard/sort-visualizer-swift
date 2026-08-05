function bitLength(value) {
  let length = 0;
  while (value > 0) {
    value >>= 1;
    length++;
  }
  return length;
}

function isMinLevel(index) {
  return bitLength(index + 1) % 2 === 1;
}

function betterThan(a, b, minLevel) {
  return minLevel ? a < b : a > b;
}

function downheap(arr, start, size) {
  let i = start;
  while (true) {
    const minLevel = isMinLevel(i);
    const left = 2 * i + 1;
    const right = 2 * i + 2;
    if (left >= size) return;
    let winner = left;
    if (right < size && betterThan(arr[right], arr[winner], minLevel))
      winner = right;
    const base = 4 * i + 3;
    for (let offset = 0; offset < 4; offset++) {
      const gc = base + offset;
      if (gc < size && betterThan(arr[gc], arr[winner], minLevel)) winner = gc;
    }
    const isGrandchild = winner >= base;
    const extreme = betterThan(arr[winner], arr[i], minLevel);
    if (!isGrandchild) {
      if (extreme) [arr[i], arr[winner]] = [arr[winner], arr[i]];
      return;
    }
    if (extreme) {
      [arr[i], arr[winner]] = [arr[winner], arr[i]];
    } else {
      return;
    }
    const parent = Math.floor((winner - 1) / 2);
    if (minLevel) {
      if (arr[winner] > arr[parent])
        [arr[parent], arr[winner]] = [arr[winner], arr[parent]];
    } else {
      if (arr[winner] < arr[parent])
        [arr[parent], arr[winner]] = [arr[winner], arr[parent]];
    }
    i = winner;
  }
}

function heapify(arr, length) {
  for (let i = Math.floor((length - 1) / 2); i >= 0; i--) {
    downheap(arr, i, length);
  }
}

function storeMax(arr, heapSize) {
  if (heapSize <= 1) return heapSize;
  let imax = 1;
  if (heapSize > 2 && arr[2] > arr[1]) imax = 2;
  const last = heapSize - 1;
  [arr[imax], arr[last]] = [arr[last], arr[imax]];
  const newSize = last;
  if (imax < newSize) downheap(arr, imax, newSize);
  return newSize;
}

function sort(arr) {
  const n = arr.length;
  if (n <= 1) return;
  heapify(arr, n);
  let heapSize = n;
  for (let i = 0; i < n - 1; i++) {
    heapSize = storeMax(arr, heapSize);
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
