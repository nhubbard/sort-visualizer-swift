const RECENCY = 8;
const EARLY_OUT_TEST_AT = 4;
const EARLY_OUT_DISORDER_FRACTION = 0.6;

const INSERT_SORT_THRESHOLD = 24;
const NINTHER_THRESHOLD = 128;
const PARTIAL_INSERT_SORT_LIMIT = 8;

function pdqLog(n) {
  let log = 0;
  while ((n >>= 1) !== 0) log++;
  return log;
}

function insertSort(arr, begin, end) {
  for (let cur = begin + 1; cur < end; cur++) {
    if (arr[cur] < arr[cur - 1]) {
      const tmp = arr[cur];
      let sift = cur;
      let siftMinusOne = cur - 1;
      do {
        arr[sift--] = arr[siftMinusOne--];
      } while (sift !== begin && tmp < arr[siftMinusOne]);
      arr[sift] = tmp;
    }
  }
}

function unguardInsertSort(arr, begin, end) {
  for (let cur = begin + 1; cur < end; cur++) {
    if (arr[cur] < arr[cur - 1]) {
      const tmp = arr[cur];
      let sift = cur;
      let siftMinusOne = cur - 1;
      do {
        arr[sift--] = arr[siftMinusOne--];
      } while (tmp < arr[siftMinusOne]);
      arr[sift] = tmp;
    }
  }
}

function partialInsertSort(arr, begin, end) {
  let limit = 0;
  for (let cur = begin + 1; cur < end; cur++) {
    if (limit > PARTIAL_INSERT_SORT_LIMIT) return false;
    if (arr[cur] < arr[cur - 1]) {
      const tmp = arr[cur];
      let sift = cur;
      let siftMinusOne = cur - 1;
      do {
        arr[sift--] = arr[siftMinusOne--];
      } while (sift !== begin && tmp < arr[siftMinusOne]);
      arr[sift] = tmp;
      limit += cur - sift;
    }
  }
  return true;
}

function sortTwo(arr, a, b) {
  if (arr[b] < arr[a]) {
    const t = arr[a];
    arr[a] = arr[b];
    arr[b] = t;
  }
}

function sortThree(arr, a, b, c) {
  sortTwo(arr, a, b);
  sortTwo(arr, b, c);
  sortTwo(arr, a, b);
}

function swap(arr, a, b) {
  const t = arr[a];
  arr[a] = arr[b];
  arr[b] = t;
}

function partRight(arr, begin, end) {
  const pivot = arr[begin];
  let first = begin;
  let last = end;

  first++;
  while (arr[first] < pivot) first++;

  if (first - 1 === begin) {
    last--;
    while (first < last && !(arr[last] < pivot)) last--;
  } else {
    last--;
    while (!(arr[last] < pivot)) last--;
  }

  const alreadyParted = first >= last;
  while (first < last) {
    swap(arr, first, last);
    first++;
    while (arr[first] < pivot) first++;
    last--;
    while (!(arr[last] < pivot)) last--;
  }

  const pivotPos = first - 1;
  arr[begin] = arr[pivotPos];
  arr[pivotPos] = pivot;

  return [pivotPos, alreadyParted];
}

function partLeft(arr, begin, end) {
  const pivot = arr[begin];
  let first = begin;
  let last = end;

  last--;
  while (pivot < arr[last]) last--;

  if (last + 1 === end) {
    first++;
    while (first < last && !(pivot < arr[first])) first++;
  } else {
    first++;
    while (!(pivot < arr[first])) first++;
  }

  while (first < last) {
    swap(arr, first, last);
    last--;
    while (pivot < arr[last]) last--;
    first++;
    while (!(pivot < arr[first])) first++;
  }

  const pivotPos = last;
  arr[begin] = arr[pivotPos];
  arr[pivotPos] = pivot;
  return pivotPos;
}

function siftDown(arr, begin, root, size) {
  while (true) {
    let child = 2 * root + 1;
    if (child >= size) break;
    if (child + 1 < size && arr[begin + child] < arr[begin + child + 1])
      child++;
    if (arr[begin + root] < arr[begin + child]) {
      swap(arr, begin + root, begin + child);
      root = child;
    } else {
      break;
    }
  }
}

function heapSort(arr, begin, end) {
  const n = end - begin;
  for (let i = Math.floor(n / 2) - 1; i >= 0; i--) siftDown(arr, begin, i, n);
  for (let i = n - 1; i > 0; i--) {
    swap(arr, begin, begin + i);
    siftDown(arr, begin, 0, i);
  }
}

function pdqLoop(arr, begin, end, badAllowed) {
  let leftmost = true;
  while (true) {
    const size = end - begin;

    if (size < INSERT_SORT_THRESHOLD) {
      if (leftmost) insertSort(arr, begin, end);
      else unguardInsertSort(arr, begin, end);
      return;
    }

    const halfSize = Math.floor(size / 2);
    if (size > NINTHER_THRESHOLD) {
      sortThree(arr, begin, begin + halfSize, end - 1);
      sortThree(arr, begin + 1, begin + halfSize - 1, end - 2);
      sortThree(arr, begin + 2, begin + halfSize + 1, end - 3);
      sortThree(
        arr,
        begin + halfSize - 1,
        begin + halfSize,
        begin + halfSize + 1,
      );
      swap(arr, begin, begin + halfSize);
    } else {
      sortThree(arr, begin + halfSize, begin, end - 1);
    }

    if (!leftmost && !(arr[begin - 1] < arr[begin])) {
      begin = partLeft(arr, begin, end) + 1;
      continue;
    }

    const [pivotPos, alreadyParted] = partRight(arr, begin, end);

    const leftSize = pivotPos - begin;
    const rightSize = end - (pivotPos + 1);
    const highUnbalance =
      leftSize < Math.floor(size / 8) || rightSize < Math.floor(size / 8);

    if (highUnbalance) {
      badAllowed--;
      if (badAllowed === 0) {
        heapSort(arr, begin, end);
        return;
      }

      if (leftSize >= INSERT_SORT_THRESHOLD) {
        swap(arr, begin, begin + Math.floor(leftSize / 4));
        swap(arr, pivotPos - 1, pivotPos - Math.floor(leftSize / 4));
        if (leftSize > NINTHER_THRESHOLD) {
          swap(arr, begin + 1, begin + (Math.floor(leftSize / 4) + 1));
          swap(arr, begin + 2, begin + (Math.floor(leftSize / 4) + 2));
          swap(arr, pivotPos - 2, pivotPos - (Math.floor(leftSize / 4) + 1));
          swap(arr, pivotPos - 3, pivotPos - (Math.floor(leftSize / 4) + 2));
        }
      }

      if (rightSize >= INSERT_SORT_THRESHOLD) {
        swap(arr, pivotPos + 1, pivotPos + (1 + Math.floor(rightSize / 4)));
        swap(arr, end - 1, end - Math.floor(rightSize / 4));
        if (rightSize > NINTHER_THRESHOLD) {
          swap(arr, pivotPos + 2, pivotPos + (2 + Math.floor(rightSize / 4)));
          swap(arr, pivotPos + 3, pivotPos + (3 + Math.floor(rightSize / 4)));
          swap(arr, end - 2, end - (1 + Math.floor(rightSize / 4)));
          swap(arr, end - 3, end - (2 + Math.floor(rightSize / 4)));
        }
      }
    } else {
      if (
        alreadyParted &&
        partialInsertSort(arr, begin, pivotPos) &&
        partialInsertSort(arr, pivotPos + 1, end)
      ) {
        return;
      }
    }

    pdqLoop(arr, begin, pivotPos, badAllowed);
    begin = pivotPos + 1;
    leftmost = false;
  }
}

function pdqSort(arr, begin, end) { if (end - begin > 1) pdqLoop(arr, begin, end, pdqLog(end - begin)); }



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
      pdqSort(arr, 0, length);
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

      let maxOfDropped = read;
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

  pdqSort(arr, write, length);

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
