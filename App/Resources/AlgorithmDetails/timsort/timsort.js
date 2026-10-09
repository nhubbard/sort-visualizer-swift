function minRunLength(value) {
  let n = value;
  let remainder = 0;
  while (n >= 32) {
    remainder |= n & 1;
    n >>= 1;
  }
  return n + remainder;
}

function countRun(values, start) {
  let end = start + 1;
  if (end === values.length) return 1;
  const descending = values[end] < values[start];
  end++;
  if (descending) {
    while (end < values.length && values[end] < values[end - 1]) end++;
    for (let left = start, right = end - 1; left < right; left++, right--) {
      [values[left], values[right]] = [values[right], values[left]];
    }
  } else {
    while (end < values.length && values[end] >= values[end - 1]) end++;
  }
  return end - start;
}

function binaryInsertion(values, start, end, sortedEnd) {
  for (let index = sortedEnd; index < end; index++) {
    const pivot = values[index];
    let low = start;
    let high = index;
    while (low < high) {
      const middle = Math.floor((low + high) / 2);
      if (values[middle] <= pivot) low = middle + 1;
      else high = middle;
    }
    for (let shift = index; shift > low; shift--)
      values[shift] = values[shift - 1];
    values[low] = pivot;
  }
}

function merge(values, runs, index) {
  const [start, leftLength] = runs[index];
  const [rightStart, rightLength] = runs[index + 1];
  const left = values.slice(start, rightStart);
  const right = values.slice(rightStart, rightStart + rightLength);
  let i = 0;
  let j = 0;
  let destination = start;
  while (i < left.length && j < right.length) {
    values[destination++] = left[i] <= right[j] ? left[i++] : right[j++];
  }
  while (i < left.length) values[destination++] = left[i++];
  while (j < right.length) values[destination++] = right[j++];
  runs.splice(index, 2, [start, leftLength + rightLength]);
}

function sort(values) {
  const n = values.length;
  if (n < 2) return;
  const minimum = minRunLength(n);
  const runs = [];
  let cursor = 0;
  while (cursor < n) {
    let length = countRun(values, cursor);
    const forced = Math.min(minimum, n - cursor);
    if (length < forced) {
      binaryInsertion(values, cursor, cursor + forced, cursor + length);
      length = forced;
    }
    runs.push([cursor, length]);
    while (runs.length > 1) {
      let index = runs.length - 2;
      if (
        (index >= 1 &&
          runs[index - 1][1] <= runs[index][1] + runs[index + 1][1]) ||
        (index >= 2 &&
          runs[index - 2][1] <= runs[index][1] + runs[index - 1][1])
      ) {
        if (runs[index - 1][1] < runs[index + 1][1]) index--;
      } else if (runs[index][1] > runs[index + 1][1]) {
        break;
      }
      merge(values, runs, index);
    }
    cursor += length;
  }
  while (runs.length > 1) {
    let index = runs.length - 2;
    if (index > 0 && runs[index - 1][1] < runs[index + 1][1]) index--;
    merge(values, runs, index);
  }
}

const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
