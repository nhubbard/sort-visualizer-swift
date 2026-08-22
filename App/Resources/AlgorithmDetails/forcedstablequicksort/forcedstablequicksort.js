function stableComp(arr, key, a, b) {
  if (arr[a] > arr[b]) return true;
  if (arr[a] === arr[b]) return key[a] > key[b];
  return false;
}

function stableSwap(arr, key, a, b) {
  [arr[a], arr[b]] = [arr[b], arr[a]];
  [key[a], key[b]] = [key[b], key[a]];
}

function medianOfThree(arr, key, a, b) {
  const m = a + Math.floor((b - 1 - a) / 2);
  if (stableComp(arr, key, a, m)) stableSwap(arr, key, a, m);
  if (stableComp(arr, key, m, b - 1)) {
    stableSwap(arr, key, m, b - 1);
    if (stableComp(arr, key, a, m)) return;
  }
  stableSwap(arr, key, a, m);
}

function partition(arr, key, a, b, p) {
  let i = a - 1;
  let j = b;
  while (true) {
    do {
      i++;
    } while (i < j && !stableComp(arr, key, i, p));
    do {
      j--;
    } while (j >= i && stableComp(arr, key, j, p));
    if (i < j) {
      stableSwap(arr, key, i, j);
    } else {
      return j;
    }
  }
}

function quickSort(arr, key, a, b) {
  if (b - a < 3) {
    if (b - a === 2 && stableComp(arr, key, a, a + 1))
      stableSwap(arr, key, a, a + 1);
    return;
  }
  medianOfThree(arr, key, a, b);
  const p = partition(arr, key, a + 1, b, a);
  stableSwap(arr, key, a, p);
  quickSort(arr, key, a, p);
  quickSort(arr, key, p + 1, b);
}

function sort(arr) {
  const n = arr.length;
  const key = [];
  for (let i = 0; i < n; i++) key.push(i);
  quickSort(arr, key, 0, n);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
