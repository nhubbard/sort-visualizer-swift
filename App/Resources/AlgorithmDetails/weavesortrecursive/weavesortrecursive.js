function sort(arr) {
  const end = arr.length;

  function compSwap(a, b) {
    if (b < end && arr[a] > arr[b]) {
      const temp = arr[a];
      arr[a] = arr[b];
      arr[b] = temp;
    }
  }

  function circle(pos, ln, gap) {
    if (ln < 2) {
      return;
    }
    let i = 0;
    while (2 * i < (ln - 1) * gap) {
      compSwap(pos + i, pos + (ln - 1) * gap - i);
      i += gap;
    }
    circle(pos, Math.floor(ln / 2), gap);
    if (pos + Math.floor((ln * gap) / 2) < end) {
      circle(pos + Math.floor((ln * gap) / 2), Math.floor(ln / 2), gap);
    }
  }

  function weaveCircle(pos, ln, gap) {
    if (ln < 2) {
      return;
    }
    weaveCircle(pos, Math.floor(ln / 2), 2 * gap);
    weaveCircle(pos + gap, Math.floor(ln / 2), 2 * gap);
    circle(pos, ln, gap);
  }

  let padded = 1;
  while (padded < end) {
    padded *= 2;
  }

  weaveCircle(0, padded, 1);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
