const INSERTION_THRESHOLD = 16;

function insertionSort(arr, lo, hi) {
  for (let i = lo + 1; i < hi; i++) {
    const key = arr[i];
    let j = i - 1;
    while (j >= lo && arr[j] > key) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[j + 1] = key;
  }
}

// Returns whichever of a, b, c indexes the middle value of the three.
function medianOfThree(arr, a, b, c) {
  if (arr[a] > arr[b]) {
    [a, b] = [b, a];
  }
  if (arr[b] > arr[c]) {
    b = c;
    if (arr[a] > arr[b]) {
      b = a;
    }
  }
  return b;
}

function fluxSortRange(arr, lo, hi, swap) {
  const n = hi - lo;
  if (n <= INSERTION_THRESHOLD) {
    insertionSort(arr, lo, hi);
    return;
  }

  const mid = lo + Math.floor(n / 2);
  const pivot = arr[medianOfThree(arr, lo, mid, hi - 1)];

  // Partition into arr (elements <= pivot) and swap (elements > pivot). Ties go to the
  // low side, which is what keeps the sort stable.
  let lowWrite = lo;
  let highWrite = 0;
  for (let read = lo; read < hi; read++) {
    const value = arr[read];
    if (value > pivot) {
      swap[highWrite] = value;
      highWrite++;
    } else {
      arr[lowWrite] = value;
      lowWrite++;
    }
  }

  for (let i = 0; i < highWrite; i++) {
    arr[lowWrite + i] = swap[i];
  }

  if (lowWrite === hi) {
    // Every element in range was <= pivot -- a run of duplicates around the pivot value
    // can cause this. There's no split to recurse into, so finish directly.
    insertionSort(arr, lo, hi);
    return;
  }

  fluxSortRange(arr, lo, lowWrite, swap);
  fluxSortRange(arr, lowWrite, hi, swap);
}

function sort(arr) {
  const n = arr.length;
  if (n < 2) return;
  const swap = new Array(n).fill(0);
  fluxSortRange(arr, 0, n, swap);
}

var array = [
  55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51,
  66, 29, 44, 12,
];
sort(array);
console.log("[" + array.join(", ") + "]");
