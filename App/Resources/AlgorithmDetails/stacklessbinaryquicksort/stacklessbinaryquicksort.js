function mostSignificantBit(value) {
  if (value === 0) return -1;
  let bit = 0;
  while (value >> (bit + 1) !== 0) bit++;
  return bit;
}

function getBit(value, bit) {
  return ((value >> bit) & 1) === 1;
}

function partition(arr, lo, hi, bit) {
  let i = lo - 1;
  let j = hi;
  while (true) {
    i++;
    while (i < j && !getBit(arr[i], bit)) i++;
    j--;
    while (j > i && getBit(arr[j], bit)) j--;
    if (i < j) {
      [arr[i], arr[j]] = [arr[j], arr[i]];
    } else {
      return i;
    }
  }
}

function sort(arr) {
  const n = arr.length;
  if (n <= 1) return;

  let maxValue = arr[0];
  for (let i = 1; i < n; i++) {
    if (arr[i] > maxValue) maxValue = arr[i];
  }

  let q = mostSignificantBit(maxValue);
  if (q < 0) return;

  let m = 0;
  let i = 0;
  let b = n;

  while (i < n) {
    const p = b - i < 1 ? i : partition(arr, i, b, q);

    if (q === 0) {
      m += 2;
      while (!getBit(m, q + 1)) q++;
      i = b;
      while (b < n && arr[b] >> (q + 1) === m >> (q + 1)) b++;
    } else {
      b = p;
      q--;
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
