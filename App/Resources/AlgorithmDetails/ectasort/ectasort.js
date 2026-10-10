// MIT License
// Copyright (c) 2020-2021 aphitorite
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

function sort(a) {
  const n = a.length;
  if (n < 2) return;
  function minRun(n) { while (n >= 32) n = Math.floor((n + 1) / 2); return n; }
  function insertion(start, end) {
    for (let i = start + 1; i < end; i++) {
      const value = a[i];
      let low = start, high = i;
      while (low < high) {
        const middle = Math.floor((low + high) / 2);
        if (a[middle] > value) high = middle;
        else low = middle + 1;
      }
      for (let j = i; j > low; j--) a[j] = a[j - 1];
      a[low] = value;
    }
  }
  if (n <= 32) { insertion(0, n); return; }
  let block = 0, bufferLength;
  if (n < 256) bufferLength = Math.floor(n / 2);
  else {
    block = minRun(n);
    while (block * block < Math.floor(n / 2)) block *= 2;
    bufferLength = 2 * block + n % block;
  }
  const buffer = new Array(bufferLength);
  const tags = new Array(block ? Math.floor((n - bufferLength) / block) + 1 : 0).fill(0);
  function copy(from, to, count) {
    if (from < to) for (let i = count - 1; i >= 0; i--) a[to + i] = a[from + i];
    else for (let i = 0; i < count; i++) a[to + i] = a[from + i];
  }
  function mergeTo(start, middle, end, destination) {
    let left = start, right = middle, output = destination;
    while (left < middle && right < end)
      a[output++] = a[left] <= a[right] ? a[left++] : a[right++];
    while (left < middle) a[output++] = a[left++];
    while (right < end) a[output++] = a[right++];
  }
  function pingPong(start, m1, m2, m3, end, workspace) {
    const second = workspace + m2 - start;
    mergeTo(start, m1, m2, workspace);
    mergeTo(m2, m3, end, second);
    mergeTo(workspace, second, workspace + end - start, start);
  }
  function mergeBackward(start, middle, end, workspace) {
    const count = end - middle;
    copy(middle, workspace, count);
    let left = middle - 1, right = workspace + count - 1, output = end;
    while (left >= start && right >= workspace)
      a[--output] = a[left] > a[right] ? a[left--] : a[right--];
    while (right >= workspace) a[--output] = a[right--];
  }
  function mergeFromBuffer(start, middle, end, count) {
    let index = 0, right = middle, output = start;
    while (index < count && right < end)
      a[output++] = a[right] >= buffer[index] ? buffer[index++] : a[right++];
    while (index < count) a[output++] = buffer[index++];
  }
  function dualMergeBackward(start, first, middle, end, count) {
    let index = count - 1, left = middle - 1, output = end;
    const split = count - (end - middle);
    while (index >= split && left >= first)
      a[--output] = a[left] < buffer[index] ? buffer[index--] : a[left--];
    if (left < first) while (index >= 0) a[--output] = buffer[index--];
    else mergeFromBuffer(start, first, output, split);
  }
  function mergeSort(start, end, workspace, initialRun, capacity) {
    let run = initialRun, index = start;
    while (index + run <= end) { insertion(index, index + run); index += run; }
    insertion(index, end);
    while (4 * run <= capacity) {
      index = start;
      while (index + 4 * run <= end) {
        pingPong(index, index + run, index + 2 * run, index + 3 * run, index + 4 * run, workspace);
        index += 4 * run;
      }
      if (index + 3 * run < end)
        pingPong(index, index + run, index + 2 * run, index + 3 * run, end, workspace);
      else if (index + 2 * run < end)
        pingPong(index, index + run, index + 2 * run, end, end, workspace);
      else if (index + run < end) mergeBackward(index, index + run, end, workspace);
      run *= 4;
    }
    while (run <= capacity) {
      index = start;
      while (index + 2 * run <= end) {
        mergeBackward(index, index + run, index + 2 * run, workspace);
        index += 2 * run;
      }
      if (index + run < end) mergeBackward(index, index + run, end, workspace);
      run *= 2;
    }
    return run;
  }
  function toBuffer(source, count) { for (let i = 0; i < count; i++) buffer[i] = a[source + i]; }
  function fromBuffer(destination, count) { for (let i = 0; i < count; i++) a[destination + i] = buffer[i]; }
  if (n < 256) {
    toBuffer(bufferLength, bufferLength);
    mergeSort(0, bufferLength, bufferLength, minRun(n), bufferLength);
    fromBuffer(bufferLength, bufferLength);
    toBuffer(0, bufferLength);
    mergeSort(bufferLength, n, 0, minRun(n), bufferLength);
    mergeFromBuffer(0, bufferLength, n, bufferLength);
    return;
  }
  function blockCycle(start, count, workspace, excludeLast, forward) {
    const stride = forward ? block : -block;
    for (let index = 0; index < count; index++) {
      let next = tags[index];
      if (index === next) continue;
      copy(start + index * stride, workspace, block);
      let current = index;
      while (true) {
        if (!(excludeLast && current === count - 1))
          copy(start + next * stride, start + current * stride, block);
        tags[current] = current;
        current = next;
        next = tags[next];
        if (next === index) break;
      }
      copy(workspace, start + current * stride, block);
      tags[current] = current;
    }
  }
  function ectaForward(start, middle, end) {
    let left = start, right = middle, tag = 0, tagCount = 0, saved = 2 * block, other = 0;
    let savedPosition = start - 2 * block, otherPosition = middle;
    do {
      const choice = saved < block ? 1 : 0;
      for (let offset = 0; offset < block; offset++) {
        const destination = (choice ? otherPosition : savedPosition) + offset;
        if (left < middle && right < end) {
          if (a[left] <= a[right]) { a[destination] = a[left++]; saved++; }
          else { a[destination] = a[right++]; other++; }
        } else if (left < middle) { a[destination] = a[left++]; saved++; }
        else { a[destination] = a[right++]; other++; }
      }
      if (choice === 0) { savedPosition += block; saved -= block; }
      else { otherPosition += block; other -= block; }
      tags[tagCount++] = choice === 0 ? tag++ : -1;
    } while (left < middle || right < end);
    if (saved > 0) tags[tagCount] = tag++;
    for (let i = 2; i < tagCount; i++) if (tags[i] === -1) tags[i] = tag++;
    blockCycle(start - 2 * block, tag, end - block, saved > 0, true);
  }
  function ectaBackward(start, middle, end) {
    let right = end - 1, left = middle - 1, tag = 0, tagCount = 0, saved = 2 * block, other = 0;
    let savedPosition = end + 2 * block, otherPosition = middle;
    do {
      const choice = saved < block ? 1 : 0;
      for (let offset = 1; offset <= block; offset++) {
        const destination = (choice ? otherPosition : savedPosition) - offset;
        if (right >= middle && left >= start) {
          if (a[right] >= a[left]) { a[destination] = a[right--]; saved++; }
          else { a[destination] = a[left--]; other++; }
        } else if (right >= middle) { a[destination] = a[right--]; saved++; }
        else { a[destination] = a[left--]; other++; }
      }
      if (choice === 0) { savedPosition -= block; saved -= block; }
      else { otherPosition -= block; other -= block; }
      tags[tagCount++] = choice === 0 ? tag++ : -1;
    } while (right >= middle || left >= start);
    if (saved > 0) tags[tagCount] = tag++;
    for (let i = 2; i < tagCount; i++) if (tags[i] === -1) tags[i] = tag++;
    blockCycle(end + block, tag, start, saved > 0, false);
  }
  let start = bufferLength, end = n;
  const dataLength = end - start;
  toBuffer(start, bufferLength);
  mergeSort(0, start, start, minRun(bufferLength), bufferLength);
  fromBuffer(start, bufferLength);
  toBuffer(0, bufferLength);
  let run = mergeSort(start, end, 0, minRun(n), bufferLength);
  let backward = false;
  while (run < dataLength) {
    let index = start;
    while (index + 2 * run <= end) { ectaForward(index, index + run, index + 2 * run); index += 2 * run; }
    if (index + run < end) ectaForward(index, index + run, end);
    else copy(index, index - 2 * block, end - index);
    run *= 2; start -= 2 * block; end -= 2 * block;
    if (run >= dataLength) { backward = true; break; }
    index = start;
    while (index + 2 * run <= end) index += 2 * run;
    if (index + run < end) ectaBackward(index, index + run, end);
    else copy(index, index + 2 * block, end - index);
    index -= 2 * run;
    while (index >= start) { ectaBackward(index, index + run, index + 2 * run); index -= 2 * run; }
    run *= 2; start += 2 * block; end += 2 * block;
  }
  if (backward) dualMergeBackward(0, start, end, n, bufferLength);
  else mergeFromBuffer(0, start, end, bufferLength);
}

const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
