function stableComp(arr, table, a, b) {
  const ta = table[a];
  const tb = table[b];
  if (arr[ta] > arr[tb]) return true;
  if (arr[ta] === arr[tb]) return table[a] > table[b];
  return false;
}

function medianOfThree(arr, table, a, b) {
  const m = a + Math.floor((b - 1 - a) / 2);
  if (stableComp(arr, table, a, m)) [table[a], table[m]] = [table[m], table[a]];
  if (stableComp(arr, table, m, b - 1)) {
    [table[m], table[b - 1]] = [table[b - 1], table[m]];
    if (stableComp(arr, table, a, m)) return;
  }
  [table[a], table[m]] = [table[m], table[a]];
}

function partition(arr, table, a, b, p) {
  let i = a - 1;
  let j = b;
  while (true) {
    do {
      i++;
    } while (i < j && !stableComp(arr, table, i, p));
    do {
      j--;
    } while (j >= i && stableComp(arr, table, j, p));
    if (i < j) {
      [table[i], table[j]] = [table[j], table[i]];
    } else {
      return j;
    }
  }
}

function quickSort(arr, table, a, b) {
  if (b - a < 3) {
    if (b - a === 2 && stableComp(arr, table, a, a + 1)) {
      [table[a], table[a + 1]] = [table[a + 1], table[a]];
    }
    return;
  }
  medianOfThree(arr, table, a, b);
  const p = partition(arr, table, a + 1, b, a);
  [table[a], table[p]] = [table[p], table[a]];
  quickSort(arr, table, a, p);
  quickSort(arr, table, p + 1, b);
}

function sort(arr) {
  const n = arr.length;
  const table = [];
  for (let i = 0; i < n; i++) table[i] = i;
  quickSort(arr, table, 0, n);
  for (let i = 0; i < n; i++) {
    if (table[i] !== i) {
      const t = arr[i];
      let j = i;
      let next = table[i];
      do {
        arr[j] = arr[next];
        table[j] = j;
        j = next;
        next = table[next];
      } while (next !== i);
      arr[j] = t;
      table[j] = j;
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
