function sort(arr) {
  const n = arr.length;
  const loops = new Array(n).fill(0);

  function pairOk(i) {
    const a = arr[loops[i]];
    const b = arr[loops[i + 1]];
    if (a < b) {
      return true;
    }
    if (a === b && loops[i] < loops[i + 1]) {
      return true;
    }
    return false;
  }

  function firstFailure() {
    let i = n - 2;
    while (i >= 0 && pairOk(i)) {
      i -= 1;
    }
    return i;
  }

  while (true) {
    const i = firstFailure();
    if (i < 0) {
      break;
    }
    for (let pos = 0; pos < n; pos++) {
      if (pos >= i && loops[pos] < n - 1) {
        loops[pos] += 1;
        break;
      } else {
        loops[pos] = 0;
      }
    }
  }

  const mapped = [];
  for (let i = 0; i < n; i++) {
    mapped.push(arr[loops[i]]);
  }
  for (let i = 0; i < n; i++) {
    arr[i] = mapped[i];
  }
}

var array = [0, 39, 21, 62, 91, 14, 23];
sort(array);
console.log("[" + array.join(", ") + "]");
