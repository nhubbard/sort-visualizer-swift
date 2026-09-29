function sort(arr) {
  const n = arr.length;
  if (n < 2) return;
  function ceilCbrt(value) {
    let low = 0,
      high = Math.min(1291, value);
    while (low < high) {
      const mid = Math.floor((low + high) / 2);
      if (mid * mid * mid >= value) high = mid;
      else low = mid + 1;
    }
    return low;
  }
  const blockLen = ceilCbrt(n);
  const runLen = blockLen * blockLen;
  const runCount = Math.floor((n - 1) / runLen) + 1;
  const keys = Array.from({ length: runCount < 2 ? n : runLen }, (_, i) => i);
  const greater = (a, b, base) =>
    arr[base + a] > arr[base + b] || (arr[base + a] === arr[base + b] && a > b);
  function tableSift(root, length, base, item) {
    let j = root;
    while (2 * j + 1 < length) {
      j = 2 * j + 1;
      if (j + 1 < length && greater(keys[j + 1], keys[j], base)) j++;
    }
    while (j > root && greater(item, keys[j], base))
      j = Math.floor((j - 1) / 2);
    while (j > root) {
      const old = keys[j];
      keys[j] = item;
      item = old;
      j = Math.floor((j - 1) / 2);
    }
    keys[root] = item;
  }
  function tableSort(start, end) {
    const length = end - start;
    if (length < 2) return;
    for (let i = Math.floor((length - 1) / 2); i >= 0; i--)
      tableSift(i, length, start, keys[i]);
    for (let i = length - 1; i > 0; i--) {
      const item = keys[i];
      keys[i] = keys[0];
      tableSift(0, i, start, item);
    }
    for (let i = 0; i < length; i++) {
      if (keys[i] !== i) {
        const held = arr[start + i];
        let j = i,
          next = keys[i];
        do {
          arr[start + j] = arr[start + next];
          keys[j] = j;
          j = next;
          next = keys[next];
        } while (next !== i);
        arr[start + j] = held;
        keys[j] = j;
      }
    }
  }
  if (runCount < 2) {
    tableSort(0, n);
    return;
  }
  const buffer = Array(runLen).fill(0);
  const heap = Array.from({ length: runCount }, (_, i) => i);
  const positions = Array(runCount).fill(0);
  const destinations = Array(runCount).fill(0);
  for (let run = 0; run < runCount; run++) {
    const start = run * runLen;
    tableSort(start, Math.min(start + runLen, n));
    positions[run] = destinations[run] = start;
  }
  function less(a, b) {
    const left = arr[positions[a]],
      right = arr[positions[b]];
    return left < right || (left === right && a < b);
  }
  function sift(item, root, size) {
    while (2 * root + 2 < size) {
      const left = 2 * root + 1;
      const child = less(heap[left], heap[left + 1]) ? left : left + 1;
      if (less(heap[child], item)) {
        heap[root] = heap[child];
        root = child;
      } else break;
    }
    const left = 2 * root + 1;
    if (left < size && less(heap[left], item)) {
      heap[root] = heap[left];
      root = left;
    }
    heap[root] = item;
  }
  for (let i = Math.floor((runCount - 1) / 2); i >= 0; i--)
    sift(heap[i], i, runCount);
  let size = runCount;
  function advance(run) {
    positions[run]++;
    if (positions[run] === Math.min((run + 1) * runLen, n)) {
      size--;
      sift(heap[size], 0, size);
    } else sift(heap[0], 0, size);
  }
  for (let i = 0; i < runLen; i++) {
    const run = heap[0];
    buffer[i] = arr[positions[run]];
    advance(run);
  }
  let t = 0,
    count = 0,
    cursor = 0;
  while (positions[cursor] - destinations[cursor] < blockLen) cursor++;
  do {
    const run = heap[0];
    arr[destinations[cursor]] = arr[positions[run]];
    positions[run]++;
    destinations[cursor]++;
    if (positions[run] === Math.min((run + 1) * runLen, n)) {
      size--;
      sift(heap[size], 0, size);
    } else sift(heap[0], 0, size);
    count++;
    if (count === blockLen) {
      keys[t++] =
        cursor > 0
          ? Math.floor(destinations[cursor] / blockLen) - blockLen - 1
          : -1;
      cursor = count = 0;
      while (positions[cursor] - destinations[cursor] < blockLen) cursor++;
    }
  } while (size > 0);
  let end = n;
  while (count > 0) {
    count--;
    destinations[cursor]--;
    end--;
    arr[end] = arr[destinations[cursor]];
  }
  positions[runCount - 1] = end;
  keys[keys.length - 1] = -1;
  t = 0;
  while (keys[t] !== -1) t++;
  let source = 0;
  for (let i = 1; i < runCount && source < destinations[0]; i++) {
    while (destinations[i] < positions[i]) {
      keys[t++] = Math.floor(destinations[i] / blockLen) - blockLen;
      while (keys[t] !== -1) t++;
      for (let x = 0; x < blockLen; x++)
        arr[destinations[i] + x] = arr[source + x];
      destinations[i] += blockLen;
      source += blockLen;
    }
  }
  for (let x = 0; x < runLen; x++) arr[x] = buffer[x];
  const blockCount = Math.floor((end - runLen) / blockLen);
  for (let i = 0; i < blockCount; i++) {
    if (keys[i] !== i) {
      for (let x = 0; x < blockLen; x++)
        buffer[x] = arr[runLen + i * blockLen + x];
      let j = i,
        next = keys[i];
      do {
        for (let x = 0; x < blockLen; x++)
          arr[runLen + j * blockLen + x] = arr[runLen + next * blockLen + x];
        keys[j] = j;
        j = next;
        next = keys[next];
      } while (next !== i);
      for (let x = 0; x < blockLen; x++)
        arr[runLen + j * blockLen + x] = buffer[x];
      keys[j] = j;
    }
  }
}

const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
