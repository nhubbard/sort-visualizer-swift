function sort(arr) {
  const n = arr.length;
  if (n < 2) return;
  const swap = (a, b) => {
    a %= n;
    b %= n;
    [arr[a], arr[b]] = [arr[b], arr[a]];
  };
  const shiftFW = (a, m, b) => {
    while (m < b) swap(a++, m++);
  };
  const shiftBW = (a, m, b) => {
    while (m > a) swap(--b, --m);
  };
  const insertion = (a, b) => {
    for (let start = a + 1; start < b; start++) {
      let i = start;
      while (i > a && arr[(i - 1) % n] > arr[i % n]) swap(i, --i);
    }
  };
  const multiSwap = (a, b, length) => {
    for (let i = 0; i < length; i++) swap(a + i, b + i);
  };
  const rotate = (start, middle, end) => {
    let left = middle - start;
    let right = end - middle;
    while (left > 0 && right > 0) {
      if (right < left) {
        multiSwap(middle - right, middle, right);
        end -= right;
        middle -= right;
        left -= right;
      } else {
        multiSwap(start, middle, left);
        start += left;
        middle += left;
        right -= left;
      }
    }
  };
  const inPlaceMerge = (a, middle, b) => {
    let i = a;
    while (i < middle && middle < b) {
      if (arr[i % n] > arr[middle % n]) {
        let k = middle + 1;
        while (k < b && arr[i % n] > arr[k % n]) k++;
        rotate(i, middle, k);
        i += k - middle;
        middle = k;
      } else i++;
    }
  };
  const merge = (p, a, middle, b, full) => {
    let i = a;
    let j = middle;
    while (i < middle && j < b) {
      if (arr[i % n] <= arr[j % n]) swap(p++, i++);
      else swap(p++, j++);
    }
    if (i < middle) {
      if (i > p) shiftFW(p, i, middle);
    } else if (full) shiftFW(p, j, b);
    return i < middle ? i : j;
  };
  const blockLess = (a, b, length) => {
    if (arr[a % n] !== arr[b % n]) return arr[a % n] < arr[b % n];
    return arr[(a + length - 1) % n] < arr[(b + length - 1) % n];
  };
  const blockMerge = (a, middle, b, length) => {
    const b1 = b - ((b - middle - 1) % length) - 1;
    if (b1 <= middle) {
      merge(a - length, a, middle, b, true);
      return;
    }
    let b2 = b1;
    for (
      let i = middle - length;
      i > a && blockLess(b1, i, length);
      i -= length
    )
      b2 -= length;
    for (let j = a; j < b1 - length; j += length) {
      let minimum = j;
      for (let i = j + length; i < b1; i += length) {
        if (blockLess(i, minimum, length)) minimum = i;
      }
      if (minimum !== j) multiSwap(j, minimum, length);
    }
    let frontier = a;
    for (let i = a + length; i < b2; i += length) {
      frontier = merge(frontier - length, frontier, i, i + length, false);
      if (frontier < i) {
        shiftBW(frontier, i, i + length);
        frontier += length;
      }
    }
    merge(frontier - length, frontier, b1, b, true);
  };
  if (n <= 16) {
    insertion(0, n);
    return;
  }
  let block = 1;
  while (block * block < n) block *= 2;
  let i = block;
  let run = 1;
  const rolling = n - i;
  let end = n;
  while (run <= block) {
    while (i + 2 * run < end) {
      merge(i - run, i, i + run, i + 2 * run, true);
      i += 2 * run;
    }
    if (i + run < end) merge(i - run, i, i + run, end, true);
    else shiftFW(i - run, i, end);
    i = end + block - run;
    end = i + rolling;
    run *= 2;
  }
  while (run < rolling) {
    while (i + 2 * run < end) {
      blockMerge(i, i + run, i + 2 * run, block);
      i += 2 * run;
    }
    if (i + run < end) blockMerge(i, i + run, end, block);
    else shiftFW(i - block, i, end);
    i = end;
    end += rolling;
    run *= 2;
  }
  insertion(i - block, i);
  inPlaceMerge(i - block, i, end);
  rotate(0, (i - block) % n, n);
}

const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log(`[${array.join(", ")}]`);
