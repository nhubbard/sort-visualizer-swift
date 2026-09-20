function sort(arr) {
  if (arr.length < 2) return;
  const n = arr.length;
  shatterSort(arr, n, 4);
}

function insertionSort(arr, start, end) {
  for (let i = start + 1; i < end; i++) {
    let pos = i;
    while (pos > start && arr[pos - 1] > arr[pos]) {
      [arr[pos - 1], arr[pos]] = [arr[pos], arr[pos - 1]];
      pos--;
    }
  }
}

function shatterPartition(arr, start, length, num) {
  let minV = arr[start];
  let maxV = arr[start];
  for (let i = 1; i < length; i++) {
    if (arr[start + i] < minV) minV = arr[start + i];
    if (arr[start + i] > maxV) maxV = arr[start + i];
  }
  const valueRange = maxV - minV + 1;
  const shatters = Math.ceil(length / num);

  const buckets = [];
  for (let i = 0; i < shatters; i++) buckets.push([]);

  for (let i = 0; i < length; i++) {
    const v = arr[start + i];
    let idx = Math.floor(((v - minV) * shatters) / valueRange);
    if (idx > shatters - 1) idx = shatters - 1;
    buckets[idx].push(v);
  }

  const offsets = new Array(shatters + 1).fill(0);
  for (let i = 0; i < shatters; i++)
    offsets[i + 1] = offsets[i] + buckets[i].length;

  let pos = start;
  for (const bucket of buckets) {
    for (const v of bucket) arr[pos++] = v;
  }
  return offsets;
}

function shatterSort(arr, length, num) {
  const offsets = shatterPartition(arr, 0, length, num);
  for (let i = 0; i < offsets.length - 1; i++) {
    if (offsets[i + 1] - offsets[i] > 1)
      insertionSort(arr, offsets[i], offsets[i + 1]);
  }
}


const array = [
  0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
];
sort(array);
console.log("[" + array.join(", ") + "]");
