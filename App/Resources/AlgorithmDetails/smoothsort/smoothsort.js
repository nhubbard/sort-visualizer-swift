const leonardo = [
  1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177, 287, 465, 753, 1219, 1973, 3193,
  5167, 8361, 13529, 21891,
];

function trailingZeroCount(value) {
  let mask = value & ~1;
  let trail = 0;
  while (mask !== 0 && (mask & 1) === 0) {
    mask >>= 1;
    trail += 1;
  }
  return trail;
}

function sift(array, pshiftIn, headIn) {
  let pshift = pshiftIn;
  let head = headIn;
  const val = array[head];
  while (pshift > 1) {
    const rt = head - 1;
    const lf = head - 1 - leonardo[pshift - 2];
    if (val >= array[lf] && val >= array[rt]) break;
    if (array[lf] >= array[rt]) {
      array[head] = array[lf];
      head = lf;
      pshift -= 1;
    } else {
      array[head] = array[rt];
      head = rt;
      pshift -= 2;
    }
  }
  array[head] = val;
}

function trinkle(array, pIn, pshiftIn, headIn, isTrustyIn) {
  let p = pIn;
  let pshift = pshiftIn;
  let head = headIn;
  let isTrusty = isTrustyIn;
  const val = array[head];
  while (p !== 1) {
    const stepson = head - leonardo[pshift];
    if (array[stepson] <= val) break;
    if (!isTrusty && pshift > 1) {
      const rt = head - 1;
      const lf = head - 1 - leonardo[pshift - 2];
      if (array[rt] >= array[stepson] || array[lf] >= array[stepson]) break;
    }
    array[head] = array[stepson];
    head = stepson;
    const trail = trailingZeroCount(p);
    p >>= trail;
    pshift += trail;
    isTrusty = false;
  }
  if (!isTrusty) {
    array[head] = val;
    sift(array, pshift, head);
  }
}

function sort(arr) {
  const n = arr.length;
  if (n <= 1) return;

  let head = 0;
  let p = 1;
  let pshift = 1;
  const hi = n - 1;

  while (head < hi) {
    if ((p & 3) === 3) {
      sift(arr, pshift, head);
      p >>= 2;
      pshift += 2;
    } else {
      if (leonardo[pshift - 1] >= hi - head) {
        trinkle(arr, p, pshift, head, false);
      } else {
        sift(arr, pshift, head);
      }
      if (pshift === 1) {
        p <<= 1;
        pshift -= 1;
      } else {
        p <<= pshift - 1;
        pshift = 1;
      }
    }
    p |= 1;
    head += 1;
  }

  trinkle(arr, p, pshift, head, false);
  while (pshift !== 1 || p !== 1) {
    if (pshift <= 1) {
      const trail = trailingZeroCount(p);
      p >>= trail;
      pshift += trail;
    } else {
      p <<= 2;
      p ^= 7;
      pshift -= 2;
      trinkle(arr, p >> 1, pshift + 1, head - leonardo[pshift] - 1, true);
      trinkle(arr, p, pshift, head - 1, true);
    }
    head -= 1;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
