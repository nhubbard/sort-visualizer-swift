function sort(arr) {
  const n = arr.length;
  function reverse(a, b) {
    for (b--; a < b; a++, b--) [arr[a], arr[b]] = [arr[b], arr[a]];
  }
  function rotate(a, m, b) {
    reverse(a, m);
    reverse(m, b);
    reverse(a, b);
  }
  function lower(a, b, value) {
    while (a < b) {
      const mid = Math.floor((a + b) / 2);
      if (value <= arr[mid]) b = mid;
      else a = mid + 1;
    }
    return a;
  }
  function upper(a, b, value) {
    while (a < b) {
      const mid = Math.floor((a + b) / 2);
      if (value < arr[mid]) b = mid;
      else a = mid + 1;
    }
    return a;
  }
  function leftGallop(a, b, value) {
    let step = 1;
    while (a - 1 + step < b && value > arr[a - 1 + step]) step *= 2;
    return lower(a + Math.floor(step / 2), Math.min(b, a - 1 + step), value);
  }
  function rightGallop(a, b, value) {
    let step = 1;
    while (b - step >= a && value < arr[b - step]) step *= 2;
    return upper(Math.max(a, b - step + 1), b - Math.floor(step / 2), value);
  }
  function insertion(a, b) {
    for (let i = a + 1; i < b; i++) {
      const value = arr[i],
        position = upper(a, i, value);
      for (let j = i; j > position; j--) arr[j] = arr[j - 1];
      arr[position] = value;
    }
  }
  function forward(a, m, b) {
    let i = a,
      j = m;
    while (i < j && j < b) {
      if (arr[i] > arr[j]) {
        const k = leftGallop(j + 1, b, arr[i]);
        rotate(i, j, k);
        i += k - j;
        j = k;
      } else i++;
    }
  }
  function backward(a, m, b) {
    let i = m - 1,
      j = b - 1;
    while (j > i && i >= a) {
      if (arr[i] > arr[j]) {
        const k = rightGallop(a, i, arr[j]);
        rotate(k, i + 1, j + 1);
        j -= i + 1 - k;
        i = k - 1;
      } else j--;
    }
  }
  function merge(a, m, b) {
    if (b - m < m - a) backward(a, m, b);
    else forward(a, m, b);
  }
  function fragmented(a, m, b, size) {
    let i = a + ((m - a) % size);
    while (i < m) {
      const j = leftGallop(m, b, arr[i]);
      rotate(i, m, j);
      const length = j - m,
        boundary = i;
      i += length;
      m += length;
      merge(a, boundary, i);
      a = i;
      i += size;
    }
    merge(Math.max(a, i - size), i, b);
  }
  if (n <= 16) {
    insertion(0, n);
    return;
  }
  let size = 1;
  while (size * size * size < n) size++;
  const group = size * size;
  for (let i = n % size; i <= n; i += size) insertion(Math.max(0, i - size), i);
  let i = n - size,
    j = n;
  while (i > 0) {
    if (j - i === group) {
      j -= group;
      i -= size;
    }
    forward(Math.max(0, i - size), i, j);
    i -= size;
  }
  for (i = n - group; i > 0; i -= group)
    fragmented(Math.max(0, i - group), i, n, size);
}

const array = [
  0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56, 10, 2, 95, 46,
  21, 74, 6, 38,
];
sort(array);
console.log("[" + array.join(", ") + "]");
