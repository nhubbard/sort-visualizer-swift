function lowerBound(s, start, end, value) {
  while (start < end) {
    let middle = start + Math.floor((end - start) / 2);
    if (s.values[middle] < value) start = middle + 1;
    else end = middle;
  }
  return start;
}
function upperBound(s, start, end, value) {
  while (start < end) {
    let middle = start + Math.floor((end - start) / 2);
    if (s.values[middle] <= value) start = middle + 1;
    else end = middle;
  }
  return start;
}
function reverse(s, start, end) {
  end--;
  while (start < end) {
    let value = s.values[start];
    s.values[start++] = s.values[end];
    s.values[end--] = value;
  }
}
function rotate(s, start, middle, end) {
  if (start >= middle || middle >= end) return;
  let left = middle - start, right = end - middle;
  if (left <= 64) {
    for (let i = 0; i < left; i++) s.buffer[i] = s.values[start + i];
    for (let i = middle; i < end; i++) s.values[i - left] = s.values[i];
    for (let i = 0; i < left; i++) s.values[end - left + i] = s.buffer[i];
  } else if (right <= 64) {
    for (let i = 0; i < right; i++) s.buffer[i] = s.values[middle + i];
    for (let i = middle - 1; i >= start; i--) s.values[i + right] = s.values[i];
    for (let i = 0; i < right; i++) s.values[start + i] = s.buffer[i];
  } else {
    reverse(s, start, middle);
    reverse(s, middle, end);
    reverse(s, start, end);
  }
}
function bufferedMerge(s, start, middle, end) {
  let leftLength = middle - start, rightLength = end - middle;
  if (leftLength <= rightLength) {
    for (let i = 0; i < leftLength; i++) s.buffer[i] = s.values[start + i];
    let left = 0, right = middle, destination = start;
    while (left < leftLength && right < end) {
      if (s.values[right] < s.buffer[left]) s.values[destination] = s.values[right++];
      else s.values[destination] = s.buffer[left++];
      destination++;
    }
    while (left < leftLength) s.values[destination++] = s.buffer[left++];
  } else {
    for (let i = 0; i < rightLength; i++) s.buffer[i] = s.values[middle + i];
    let left = middle - 1, right = rightLength - 1, destination = end - 1;
    while (left >= start && right >= 0) {
      if (s.values[left] > s.buffer[right]) s.values[destination] = s.values[left--];
      else s.values[destination] = s.buffer[right--];
      destination--;
    }
    while (right >= 0) s.values[destination--] = s.buffer[right--];
  }
}
function merge(s, start, middle, end) {
  if (start >= middle || middle >= end || s.values[middle - 1] <= s.values[middle]) return;
  let leftLength = middle - start, rightLength = end - middle;
  if ((leftLength < rightLength ? leftLength : rightLength) <= 64) {
    bufferedMerge(s, start, middle, end);
    return;
  }
  let leftSplit, rightSplit;
  if (leftLength >= rightLength) {
    leftSplit = start + Math.floor(leftLength / 2);
    rightSplit = lowerBound(s, middle, end, s.values[leftSplit]);
  } else {
    rightSplit = middle + Math.floor(rightLength / 2);
    leftSplit = upperBound(s, start, middle, s.values[rightSplit]);
  }
  rotate(s, leftSplit, middle, rightSplit);
  let newMiddle = leftSplit + rightSplit - middle;
  merge(s, start, leftSplit, newMiddle);
  merge(s, newMiddle, rightSplit, end);
}
function insertion(s, start, end) {
  for (let index = start + 1; index < end; index++) {
    let value = s.values[index];
    let destination = upperBound(s, start, index, value);
    for (let cursor = index; cursor > destination; cursor--)
      s.values[cursor] = s.values[cursor - 1];
    s.values[destination] = value;
  }
}
function sort(values, count) {
  if (count < 2) return;
  let s = {values: values, buffer: new Array(64).fill(0)};
  for (let start = 0; start < count; start += 32) {
    let end = start + 32 < count ? start + 32 : count;
    insertion(s, start, end);
  }
  for (let run = 32; run < count; run *= 2)
    for (let start = 0; start + run < count; start += 2 * run) {
      let end = start + 2 * run < count ? start + 2 * run : count;
      merge(s, start, start + run, end);
    }
}

const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array, array.length);
console.log("[" + array.join(", ") + "]");
