function sort(arr) {
  quicksortTernaryLR(arr, 0, arr.length - 1);
}

function compare3(arr, a, b) {
  if (arr[a] === arr[b]) return 0;
  return arr[a] > arr[b] ? 1 : -1;
}

function selectPivot(arr, lo, hi) {
  const mid = Math.floor((lo + hi) / 2);
  const cLoMid = compare3(arr, lo, mid);
  if (cLoMid === 0) return lo;
  const cLoHi = compare3(arr, lo, hi - 1);
  const cMidHi = compare3(arr, mid, hi - 1);
  if (cLoHi === 0 || cMidHi === 0) return hi - 1;

  if (cLoMid < 0) {
    return cMidHi < 0 ? mid : cLoHi < 0 ? hi - 1 : lo;
  } else {
    return cMidHi > 0 ? mid : cLoHi < 0 ? lo : hi - 1;
  }
}

function quicksortTernaryLR(arr, lo, hi) {
  if (hi <= lo) return;

  const piv = selectPivot(arr, lo, hi + 1);
  [arr[piv], arr[hi]] = [arr[hi], arr[piv]];
  const pivotIndex = hi;

  let i = lo,
    j = hi - 1;
  let p = lo,
    q = hi - 1;

  for (;;) {
    let cmp;
    while (i <= j && (cmp = compare3(arr, i, pivotIndex)) <= 0) {
      if (cmp === 0) {
        [arr[i], arr[p]] = [arr[p], arr[i]];
        p++;
      }
      i++;
    }
    while (i <= j && (cmp = compare3(arr, j, pivotIndex)) >= 0) {
      if (cmp === 0) {
        [arr[j], arr[q]] = [arr[q], arr[j]];
        q--;
      }
      j--;
    }
    if (i > j) break;
    [arr[i], arr[j]] = [arr[j], arr[i]];
    i++;
    j--;
  }

  [arr[i], arr[hi]] = [arr[hi], arr[i]];

  const numLess = i - p;
  const numGreater = q - j;

  j = i - 1;
  i = i + 1;

  const pe = lo + Math.min(p - lo, numLess);
  for (let k = lo; k < pe; k++, j--) {
    [arr[k], arr[j]] = [arr[j], arr[k]];
  }

  const qe = hi - 1 - Math.min(hi - 1 - q, numGreater - 1);
  for (let k = hi - 1; k > qe; k--, i++) {
    [arr[i], arr[k]] = [arr[k], arr[i]];
  }

  quicksortTernaryLR(arr, lo, lo + numLess - 1);
  quicksortTernaryLR(arr, hi - numGreater + 1, hi);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
