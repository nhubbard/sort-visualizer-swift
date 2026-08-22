const INSERT_SORT_THRESHOLD = 24;
const NINTHER_THRESHOLD = 128;
const PARTIAL_INSERT_SORT_LIMIT = 8;
const BLOCK_SIZE = 64;
const CACHELINE_SIZE = 64;

function pdqLog(n) {
  let log = 0;
  while ((n >>= 1) !== 0) log++;
  return log;
}

function truncDiv(a, b) {
  // Integer division truncated toward zero. JavaScript's `/` produces a float, and this
  // is the one call site where the dividend can go negative, so plain Math.floor would
  // disagree with C/Java/Swift/etc. semantics there.
  return Math.trunc(a / b);
}

function swap(arr, a, b) {
  const t = arr[a];
  arr[a] = arr[b];
  arr[b] = t;
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
  if (arr[b] < arr[a]) swap(arr, a, b);
}

function sortThree(arr, a, b, c) {
  sortTwo(arr, a, b);
  sortTwo(arr, b, c);
  sortTwo(arr, a, b);
}

function swapOffsets(
  arr,
  first,
  last,
  leftOffsets,
  leftPos,
  rightOffsets,
  rightPos,
  num,
  useSwaps,
) {
  if (useSwaps) {
    for (let i = 0; i < num; i++) {
      swap(
        arr,
        first + leftOffsets[leftPos + i],
        last - rightOffsets[rightPos + i],
      );
    }
  } else if (num > 0) {
    let left = first + leftOffsets[leftPos];
    let right = last - rightOffsets[rightPos];
    const tmp = arr[left];
    arr[left] = arr[right];
    for (let i = 1; i < num; i++) {
      left = first + leftOffsets[leftPos + i];
      arr[right] = arr[left];
      right = last - rightOffsets[rightPos + i];
      arr[left] = arr[right];
    }
    arr[right] = tmp;
  }
}

function partRightBranchless(arr, begin, end, leftOffsets, rightOffsets) {
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
  if (!alreadyParted) {
    swap(arr, first, last);
    first++;
  }

  let leftNum = 0,
    rightNum = 0,
    leftStart = 0,
    rightStart = 0;

  while (last - first > 2 * BLOCK_SIZE) {
    if (leftNum === 0) {
      leftStart = 0;
      let it = first;
      for (let i = 0; i < BLOCK_SIZE; i++) {
        leftOffsets[leftNum] = i;
        if (!(arr[it] < pivot)) leftNum++;
        it++;
      }
    }
    if (rightNum === 0) {
      rightStart = 0;
      let it = last;
      for (let i = 0; i < BLOCK_SIZE; i++) {
        it--;
        rightOffsets[rightNum] = i + 1;
        if (arr[it] < pivot) rightNum++;
      }
    }

    const num = Math.min(leftNum, rightNum);
    swapOffsets(
      arr,
      first,
      last,
      leftOffsets,
      leftStart,
      rightOffsets,
      rightStart,
      num,
      leftNum === rightNum,
    );
    leftNum -= num;
    rightNum -= num;
    leftStart += num;
    rightStart += num;
    if (leftNum === 0) first += BLOCK_SIZE;
    if (rightNum === 0) last -= BLOCK_SIZE;
  }

  let leftSize = 0,
    rightSize = 0;
  const unknownLeft =
    last - first - (rightNum !== 0 || leftNum !== 0 ? BLOCK_SIZE : 0);
  if (rightNum !== 0) {
    leftSize = unknownLeft;
    rightSize = BLOCK_SIZE;
  } else if (leftNum !== 0) {
    leftSize = BLOCK_SIZE;
    rightSize = unknownLeft;
  } else {
    leftSize = truncDiv(unknownLeft, 2);
    rightSize = unknownLeft - leftSize;
  }

  if (unknownLeft !== 0 && leftNum === 0) {
    leftStart = 0;
    let it = first;
    for (let i = 0; i < leftSize; i++) {
      leftOffsets[leftNum] = i;
      if (!(arr[it] < pivot)) leftNum++;
      it++;
    }
  }

  if (unknownLeft !== 0 && rightNum === 0) {
    rightStart = 0;
    let it = last;
    for (let i = 0; i < rightSize; i++) {
      it--;
      rightOffsets[rightNum] = i + 1;
      if (arr[it] < pivot) rightNum++;
    }
  }

  const num = Math.min(leftNum, rightNum);
  swapOffsets(
    arr,
    first,
    last,
    leftOffsets,
    leftStart,
    rightOffsets,
    rightStart,
    num,
    leftNum === rightNum,
  );
  leftNum -= num;
  rightNum -= num;
  leftStart += num;
  rightStart += num;
  if (leftNum === 0) first += leftSize;
  if (rightNum === 0) last -= rightSize;

  let leftOffsetsPos = 0;
  let rightOffsetsPos = 0;

  if (leftNum !== 0) {
    leftOffsetsPos += leftStart;
    while (leftNum-- !== 0) {
      swap(arr, first + leftOffsets[leftOffsetsPos + leftNum], --last);
    }
    first = last;
  }

  if (rightNum !== 0) {
    rightOffsetsPos += rightStart;
    while (rightNum-- !== 0) {
      swap(arr, last - rightOffsets[rightOffsetsPos + rightNum], first++);
    }
    last = first;
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

function pdqLoop(arr, begin, end, badAllowed, leftOffsets, rightOffsets) {
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

    const [pivotPos, alreadyParted] = partRightBranchless(
      arr,
      begin,
      end,
      leftOffsets,
      rightOffsets,
    );

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

    pdqLoop(arr, begin, pivotPos, badAllowed, leftOffsets, rightOffsets);
    begin = pivotPos + 1;
    leftmost = false;
  }
}

function sort(arr) {
  const n = arr.length;
  if (n < 2) return;
  const leftOffsets = new Array(BLOCK_SIZE + CACHELINE_SIZE).fill(0);
  const rightOffsets = new Array(BLOCK_SIZE + CACHELINE_SIZE).fill(0);
  pdqLoop(arr, 0, n, pdqLog(n), leftOffsets, rightOffsets);
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
