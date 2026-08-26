const RECENCY = 8;
const EARLY_OUT_TEST_AT = 4;
const EARLY_OUT_DISORDER_FRACTION = 0.6;

function quicksort(arr, lo, hi) {
  // A plain general-purpose sort for arr[lo..hi), used both as the early-out fallback and to
  // sort the leftover "dropped" elements before the final merge. Any decent O(n log n) sort
  // works here -- the algorithm doesn't depend on which one.
  if (hi - lo <= 1) return;
  const pivot = arr[lo + Math.floor((hi - lo) / 2)];
  const less = [];
  const equal = [];
  const greater = [];

  for (let i = lo; i < hi; i++) {
    if (arr[i] < pivot) {
      less.push(arr[i]);
    } else if (arr[i] > pivot) {
      greater.push(arr[i]);
    } else {
      equal.push(arr[i]);
    }
  }

  quicksort(less, 0, less.length);
  quicksort(greater, 0, greater.length);

  const merged = less.concat(equal, greater);
  for (let i = 0; i < merged.length; i++) {
    arr[lo + i] = merged[i];
  }
}

function sort(arr) {
  const length = arr.length;
  if (length < 2) return;

  const dropped = [];
  let numDroppedInARow = 0;
  let read = 0;
  let write = 0;
  let iteration = 0;
  const earlyOutStop = Math.floor(length / EARLY_OUT_TEST_AT);

  while (read < length) {
    iteration++;
    if (
      iteration === earlyOutStop &&
      dropped.length > read * EARLY_OUT_DISORDER_FRACTION
    ) {
      // Too disordered for the adaptive approach to be worth it: flush what's been dropped so
      // far back into the array and fall back to a plain full sort.
      for (const value of dropped) {
        arr[write] = value;
        write++;
      }
      dropped.length = 0;
      quicksort(arr, 0, length);
      return;
    }

    if (write === 0 || arr[read] >= arr[write - 1]) {
      // In order -- keep it.
      arr[write] = arr[read];
      write++;
      read++;
      numDroppedInARow = 0;
    } else if (
      numDroppedInARow === 0 &&
      write >= 2 &&
      arr[read] >= arr[write - 2]
    ) {
      // Quick undo: the element two back would have accepted this one just fine, so drop the
      // one right before it instead of the new element.
      dropped.push(arr[write - 1]);
      arr[write - 1] = arr[read];
      read++;
    } else if (numDroppedInARow < RECENCY) {
      dropped.push(arr[read]);
      read++;
      numDroppedInARow++;
    } else {
      // Accepting something `numDroppedInARow` elements back made every subsequent element
      // drop -- that accept was a mistake. Undo it, and any other recently accepted elements
      // bigger than the dropped run's maximum.
      dropped.splice(dropped.length - numDroppedInARow, numDroppedInARow);
      read -= numDroppedInARow;

      let numBacktracked = 1;
      write--;

      let maxOfDropped = arr[read];
      for (let i = read + 1; i <= read + numDroppedInARow; i++) {
        if (arr[i] > maxOfDropped) maxOfDropped = arr[i];
      }

      while (write >= 1 && maxOfDropped < arr[write - 1]) {
        write--;
        numBacktracked++;
      }

      for (let i = write; i < write + numBacktracked; i++) {
        dropped.push(arr[i]);
      }

      numDroppedInARow = 0;
    }
  }

  for (let offset = 0; offset < dropped.length; offset++) {
    arr[write + offset] = dropped[offset];
  }

  quicksort(arr, write, length);

  // Copy the now-sorted dropped tail before the final backward merge starts overwriting
  // arr[write:] in place.
  const buffer = arr.slice(write, write + dropped.length);

  let i = buffer.length - 1;
  let j = write - 1;
  let k = length - 1;

  while (i >= 0) {
    if (j < 0 || buffer[i] > arr[j]) {
      arr[k] = buffer[i];
      k--;
      i--;
    } else {
      arr[k] = arr[j];
      k--;
      j--;
    }
  }
}

var array = [
  0, 1, 2, 3, 4, 9, 6, 7, 8, 5, 10, 11, 12, 13, 14, 15, 21, 17, 18, 19, 20, 16,
  22, 23, 24, 28, 26, 27, 25, 29,
];
sort(array);
console.log("[" + array.join(", ") + "]");
