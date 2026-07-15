function sort(arr) {
  const n = arr.length;
  const loops = new Array(n).fill(0);
  while (true) {
    let isSorted = true;
    for (let i = 0; i < n - 1; i++) {
      const a = arr[loops[i]];
      const b = arr[loops[i + 1]];
      if (a < b || (a === b && loops[i] < loops[i + 1])) {
        continue;
      }
      isSorted = false;
      break;
    }
    if (isSorted) {
      break;
    }
    for (let pos = 0; pos < n; pos++) {
      loops[pos] = Math.floor(Math.random() * n);
    }
  }

  const mapped = loops.map((i) => arr[i]);
  for (let i = 0; i < n; i++) {
    arr[i] = mapped[i];
  }
}

var array = [0, 39, 21, 62, 14];
sort(array);
console.log("[" + array.join(", ") + "]");
