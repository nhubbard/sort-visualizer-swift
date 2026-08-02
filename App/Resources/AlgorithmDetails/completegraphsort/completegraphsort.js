function compSwap(arr, a, b) {
  if (arr[a] > arr[b]) {
    const tmp = arr[a];
    arr[a] = arr[b];
    arr[b] = tmp;
  }
}

function split(arr, a, m, b) {
  if (b - a < 2) return;
  let c = 0;
  const len1 = Math.floor((b - a) / 2);
  const odd = (b - a) % 2 === 1;
  if (odd) {
    if (m - a > b - m) {
      c = a;
      a++;
    } else {
      b--;
      c = b;
    }
  }
  for (let s = 0; s < len1; s++) {
    let i = a;
    for (let j = s; j < len1; j++) compSwap(arr, i++, m + j);
    for (let j = 0; j < s; j++) compSwap(arr, i++, m + j);
  }
  if (odd) {
    if (c < m) {
      for (let j = 0; j < len1; j++) compSwap(arr, c, m + j);
    } else {
      for (let j = 0; j < len1; j++) compSwap(arr, a + j, c);
    }
  }
}

function sort(arr) {
  const n = arr.length;
  let d = 2;
  const end = 1 << Math.trunc(Math.log(n - 1) / Math.log(2) + 1);
  while (d <= end) {
    let i = 0,
      dec = 0;
    while (i < n) {
      let j = i;
      dec += n;
      while (dec >= d) {
        dec -= d;
        j++;
      }
      let k = j;
      dec += n;
      while (dec >= d) {
        dec -= d;
        k++;
      }
      split(arr, i, j, k);
      i = k;
    }
    d *= 2;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
