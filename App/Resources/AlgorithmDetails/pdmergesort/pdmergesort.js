function reverseRun(arr, lo, hi) {
  while (lo < hi) {
    const t = arr[lo];
    arr[lo] = arr[hi];
    arr[hi] = t;
    lo++;
    hi--;
  }
}

/* Finds the maximal run starting at indexIn (every adjacent step in the same
 * direction), reversing it in place if that direction was descending.
 * Returns the index where the next run starts, or -1 if this was the last
 * run. */
function identifyRun(arr, indexIn, n) {
  if (indexIn >= n - 1) {
    return -1;
  }
  const startIndex = indexIn;
  let index = indexIn;
  const ascending = arr[index] <= arr[index + 1];
  index++;
  while (index < n - 1) {
    const stepAscending = arr[index] <= arr[index + 1];
    if (stepAscending !== ascending) {
      break;
    }
    index++;
  }
  if (!ascending) {
    reverseRun(arr, startIndex, index);
  }
  return index >= n - 1 ? -1 : index + 1;
}

/* Merges arr[start..mid) with arr[mid..end) by copying the left run into a
 * scratch buffer and merging forward from the low end. */
function mergeUp(arr, start, mid, end, buffer) {
  for (let i = 0; i < mid - start; i++) {
    buffer[i] = arr[start + i];
  }
  let bufferPointer = 0;
  let left = start;
  let right = mid;
  while (left < right && right < end) {
    if (buffer[bufferPointer] <= arr[right]) {
      arr[left] = buffer[bufferPointer];
      bufferPointer++;
    } else {
      arr[left] = arr[right];
      right++;
    }
    left++;
  }
  while (left < right) {
    arr[left] = buffer[bufferPointer];
    bufferPointer++;
    left++;
  }
}

/* Merges arr[start..mid) with arr[mid..end) by copying the right run into a
 * scratch buffer and merging backward from the high end. */
function mergeDown(arr, start, mid, end, buffer) {
  for (let i = 0; i < end - mid; i++) {
    buffer[i] = arr[mid + i];
  }
  let bufferPointer = end - mid - 1;
  let left = mid - 1;
  let right = end - 1;
  while (right > left && left >= start) {
    if (buffer[bufferPointer] >= arr[left]) {
      arr[right] = buffer[bufferPointer];
      bufferPointer--;
    } else {
      arr[right] = arr[left];
      left--;
    }
    right--;
  }
  while (right > left) {
    arr[right] = buffer[bufferPointer];
    bufferPointer--;
    right--;
  }
}

/* Picks whichever of mergeUp/mergeDown needs the smaller scratch copy. */
function mergeRuns(arr, leftStart, rightStart, end, buffer) {
  if (end - rightStart < rightStart - leftStart) {
    mergeDown(arr, leftStart, rightStart, end, buffer);
  } else {
    mergeUp(arr, leftStart, rightStart, end, buffer);
  }
}

function sort(arr) {
  const n = arr.length;
  if (n < 2) {
    return;
  }

  let runs = [];
  let lastRun = 0;
  while (lastRun !== -1) {
    runs.push(lastRun);
    lastRun = identifyRun(arr, lastRun, n);
  }

  const buffer = new Array(n);
  let runCount = runs.length;
  while (runCount > 1) {
    let i = 0;
    while (i < runCount - 1) {
      const end = i + 2 >= runCount ? n : runs[i + 2];
      mergeRuns(arr, runs[i], runs[i + 1], end, buffer);
      i += 2;
    }

    const compacted = [];
    for (let j = 0; j < runCount; j += 2) {
      compacted.push(runs[j]);
    }
    runs = compacted;
    runCount = runs.length;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
