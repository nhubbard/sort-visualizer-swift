function sort(arr) {
  const end = arr.length;

  function compSwap(a, b) {
    if (b < end && arr[a] > arr[b]) {
      const temp = arr[a];
      arr[a] = arr[b];
      arr[b] = temp;
    }
  }

  let padded = 1;
  while (padded < end) {
    padded *= 2;
  }

  let i = 1;
  while (i < padded) {
    let j = 1;
    while (j <= i) {
      let k = 0;
      while (k < padded) {
        const d = Math.floor(Math.floor(padded / i) / 2);
        let m = 0;
        let l = Math.floor(padded / j) - d;
        while (l >= Math.floor(Math.floor(padded / j) / 2)) {
          let p = 0;
          while (p < d) {
            compSwap(k + m, k + l + p);
            p++;
            m++;
          }
          l -= d;
        }
        k += Math.floor(padded / j);
      }
      j *= 2;
    }
    i *= 2;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
