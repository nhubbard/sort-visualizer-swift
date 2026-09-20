function sort(arr) {
  const n = arr.length;
  if (n < 2) return;
  function blockSwap(a, b, size) {
    for (let offset = 0; offset < size; offset++) {
      const x = a - size + 1 + offset, y = b - size + 1 + offset;
      [arr[x], arr[y]] = [arr[y], arr[x]];
    }
  }
  function blockInsert(a, b, size) {
    while (a - size >= b) { blockSwap(a - size, a, size); a -= size; }
  }
  function blockReversal(a, b, size) {
    b -= size;
    while (b > a) { blockSwap(a, b, size); a += size; b -= size; }
  }
  function blockSearch(a, b, size, value) {
    while (a < b) {
      const mid = a + Math.floor(Math.floor((b - a) / size) / 2) * size;
      if (value < arr[mid]) b = mid;
      else a = mid + size;
    }
    return a;
  }
  function order(a, b, size) {
    let i = a, j = i + size;
    while (j < b) { blockInsert(j, i, size); i += size; j += 2 * size; }
    const mid = a + Math.floor(Math.floor((b - a) / size) / 2) * size;
    blockReversal(mid, b, size);
  }
  let k = 1;
  while (2 * k <= n) {
    for (let i = 2 * k - 1; i < n; i += 2 * k) {
      if (arr[i - k] > arr[i]) blockSwap(i - k, i, k);
    }
    k *= 2;
  }
  while (k > 0) {
    const a = k - 1;
    let i = a + 2 * k, g = 2, p = 4;
    while (i + 2 * k * g - k <= n) {
      order(i, i + 2 * k * g - k, k);
      const b = a + k * (p - 1);
      i += k * g - k;
      for (let j = i; j < i + k * g; j += k)
        blockInsert(j, blockSearch(a, b, k, arr[j]), k);
      i += k * g + k;
      g = p - g; p *= 2;
    }
    while (i < n) {
      blockInsert(i, blockSearch(a, i, k, arr[i]), k);
      i += 2 * k;
    }
    k = Math.floor(k / 2);
  }
}

var array = [
  34, 7, 23, 90, 12, 56, 3, 45, 78, 21, 66, 9, 50, 15, 88, 40, 61, 5, 33, 72,
  18, 95, 27, 60,
];
sort(array);
console.log("[" + array.join(", ") + "]");
