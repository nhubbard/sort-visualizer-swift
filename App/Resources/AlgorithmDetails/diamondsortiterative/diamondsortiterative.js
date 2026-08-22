function sort(arr) {
  const n = arr.length;

  function compSwap(a, b) {
    if (arr[a] > arr[b]) {
      const t = arr[a];
      arr[a] = arr[b];
      arr[b] = t;
    }
  }

  let p = 1;
  while (p < n) {
    p *= 2;
  }

  let m = 4;
  while (m <= p) {
    for (let k = 0; k < m / 2; k++) {
      const cnt = k <= m / 4 ? k : m / 2 - k;
      let j = 0;
      while (j < n) {
        if (j + cnt + 1 < n) {
          let i = j + cnt;
          while (i + 1 < Math.min(n, j + m - cnt)) {
            compSwap(i, i + 1);
            i += 2;
          }
        }
        j += m;
      }
    }
    m *= 2;
  }
  m = Math.floor(m / 2);
  for (let k = 0; k <= Math.floor(m / 2); k++) {
    let i = k;
    while (i + 1 < Math.min(n, m - k)) {
      compSwap(i, i + 1);
      i += 2;
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
