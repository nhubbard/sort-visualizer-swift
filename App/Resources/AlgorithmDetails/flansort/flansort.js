function sort(arr) {
  const n = arr.length;
  if (n < 2) return;
  const gap = 14,
    ratio = 4;
  const positions = Array(gap + 2).fill(0),
    heap = Array(gap + 2).fill(0);
  const mask = (1n << 64n) - 1n;
  let state = 0x9e3779b97f4a7c15n;
  for (const value of arr)
    state =
      ((state ^ (BigInt(value) & mask)) * 0xbf58476d1ce4e5b9n +
        0x94d049bb133111ebn) &
      mask;
  function randomChoice(count) {
    state ^= state >> 12n;
    state ^= (state << 25n) & mask;
    state ^= state >> 27n;
    return Number(((state * 0x2545f4914f6cdd1dn) & mask) % BigInt(count));
  }
  function swap(i, j) {
    const t = arr[i];
    arr[i] = arr[j];
    arr[j] = t;
  }
  function median(a, m, b) {
    if (arr[m] > arr[a]) {
      if (arr[m] < arr[b]) return m;
      return arr[a] > arr[b] ? a : b;
    }
    if (arr[m] > arr[b]) return m;
    return arr[a] < arr[b] ? a : b;
  }
  function ninther(a, b) {
    const step = Math.floor((b - a) / 9);
    return median(
      median(a, a + step, a + 2 * step),
      median(a + 3 * step, a + 4 * step, a + 5 * step),
      median(a + 6 * step, a + 7 * step, a + 8 * step),
    );
  }
  function pivotIndex(a, b) {
    const step = Math.floor((b - a) / 3);
    return median(
      ninther(a, a + step),
      ninther(a + step, a + 2 * step),
      ninther(a + 2 * step, b),
    );
  }
  function binSearch(a, b, value, backward) {
    while (a < b) {
      const m = a + Math.floor((b - a) / 2);
      const found = backward ? arr[m] < value : arr[m] > value;
      if (found) b = m;
      else a = m + 1;
    }
    return a;
  }
  function insertTo(value, start, end) {
    while (start > end) {
      start--;
      arr[start + 1] = arr[start];
    }
    arr[end] = value;
  }
  function binaryInsertion(a, b) {
    for (let i = a + 1; i < b; i++) {
      const value = arr[i];
      insertTo(value, i, binSearch(a, i, value, false));
    }
  }
  function blockSearch(a, b, value, right) {
    while (a < b) {
      const m = a + Math.floor(Math.floor((b - a) / (gap + 1)) / 2) * (gap + 1);
      const found = right ? arr[m] > value : arr[m] >= value;
      if (found) b = m;
      else a = m + gap + 1;
    }
    return a;
  }
  function retrieve(i, p, pEnd, boundary, backward) {
    let j = i - 1,
      k = pEnd - (gap + 1);
    while (k > p + gap) {
      let m = binSearch(k - gap, k, boundary, backward) - 1;
      k -= gap + 1;
      while (m >= k) {
        swap(j--, m--);
      }
    }
    let m = binSearch(p, p + gap, boundary, backward) - 1;
    while (m >= p) {
      swap(j--, m--);
    }
  }
  function librarySort(a, b, p, boundary, backward) {
    const length = b - a;
    if (length < 32) {
      binaryInsertion(a, b);
      return;
    }
    let s = length;
    while (s >= 32) s = Math.floor((s - 1) / ratio) + 1;
    let i = a + s,
      j = a + ratio * s,
      pEnd = p + (s + 1) * (gap + 1) + gap;
    binaryInsertion(a, i);
    for (let k = 0; k < s; k++) swap(a + k, p + k * (gap + 1) + gap);
    while (i < b) {
      if (i === j) {
        retrieve(i, p, pEnd, boundary, backward);
        s = i - a;
        pEnd = p + (s + 1) * (gap + 1) + gap;
        j = a + (j - a) * ratio;
        for (let k = 0; k < s; k++) swap(a + k, p + k * (gap + 1) + gap);
      }
      const value = arr[i];
      let block = blockSearch(p + gap, pEnd - (gap + 1), value, false);
      if (arr[block] === value) {
        const equalEnd = blockSearch(
          block + gap + 1,
          pEnd - (gap + 1),
          value,
          true,
        );
        block +=
          randomChoice(Math.floor((equalEnd - block) / (gap + 1))) * (gap + 1);
      }
      const loc = binSearch(block - gap, block, boundary, backward);
      if (loc === block) {
        do {
          block += gap + 1;
        } while (
          block < pEnd &&
          binSearch(block - gap, block, boundary, backward) === block
        );
        if (block === pEnd) {
          retrieve(i, p, pEnd, boundary, backward);
          s = i - a;
          pEnd = p + (s + 1) * (gap + 1) + gap;
          j = a + (j - a) * ratio;
          for (let k = 0; k < s; k++) swap(a + k, p + k * (gap + 1) + gap);
        } else {
          const rotP = binSearch(block - gap, block, boundary, backward);
          const rotS = block - Math.max(rotP, block - Math.floor(gap / 2));
          let m = block - rotS,
            end = block;
          while (m > loc - rotS) swap(--end, --m);
        }
      } else {
        const displaced = arr[loc];
        arr[i++] = displaced;
        insertTo(value, loc, binSearch(block - gap, loc, value, false));
      }
    }
    retrieve(b, p, pEnd, boundary, backward);
  }
  function merge(runLength, b, destination, runCount) {
    if (runCount < 2) {
      if (runCount === 1) {
        while (positions[0] < b) swap(destination++, positions[0]++);
      }
      return;
    }
    const a = positions[0];
    for (let i = 0; i < runCount; i++) heap[i] = i;
    function less(i, j) {
      const left = arr[positions[i]],
        right = arr[positions[j]];
      return left < right || (left === right && i < j);
    }
    function sift(item, root, size) {
      while (2 * root + 2 < size) {
        const left = 2 * root + 1;
        const child = less(heap[left], heap[left + 1]) ? left : left + 1;
        if (less(heap[child], item)) {
          heap[root] = heap[child];
          root = child;
        } else break;
      }
      const left = 2 * root + 1;
      if (left < size && less(heap[left], item)) {
        heap[root] = heap[left];
        root = left;
      }
      heap[root] = item;
    }
    for (let i = Math.floor((runCount - 1) / 2); i >= 0; i--)
      sift(heap[i], i, runCount);
    let size = runCount;
    while (size > 0) {
      const run = heap[0];
      swap(destination++, positions[run]++);
      if (positions[run] === Math.min(a + (run + 1) * runLength, b)) {
        size--;
        sift(heap[size], 0, size);
      } else sift(heap[0], 0, size);
    }
  }
  let a = 0,
    b = n;
  while (b - a >= 32) {
    const pivot = arr[pivotIndex(a, b)];
    let first = a,
      i = a - 1,
      j = b,
      last = b;
    while (true) {
      i++;
      while (i < j) {
        if (arr[i] === pivot) swap(first++, i);
        else if (arr[i] < pivot) break;
        i++;
      }
      j--;
      while (j > i) {
        if (arr[j] === pivot) swap(--last, j);
        else if (arr[j] > pivot) break;
        j--;
      }
      if (i < j) swap(i, j);
      else {
        if (first === b) return;
        if (j < i) j++;
        while (first > a) swap(--i, --first);
        while (last < b) swap(j++, last++);
        break;
      }
    }
    let left = i - a,
      right = b - j,
      runCount = 0;
    if (left <= right) {
      let m = b - left;
      left = Math.max(Math.floor((right + 1) / (gap + 1)), 16);
      for (let k = a; k < i; k += left) {
        librarySort(k, Math.min(k + left, i), j, pivot, true);
        positions[runCount++] = k;
      }
      merge(left, i, m, runCount);
      if (j - i < m - j) {
        while (i < j) swap(i++, --m);
        b = m;
      } else {
        while (m > j) swap(i++, --m);
        b = i;
      }
    } else {
      let m = a + right;
      right = Math.max(Math.floor((left + 1) / (gap + 1)), 16);
      for (let k = j; k < b; k += right) {
        librarySort(k, Math.min(k + right, b), a, pivot, false);
        positions[runCount++] = k;
      }
      merge(right, b, a, runCount);
      if (i - m < j - i) {
        while (m < i) swap(m++, --j);
        a = j;
      } else {
        while (j > i) swap(m++, --j);
        a = m;
      }
    }
  }
  binaryInsertion(a, b);
}

const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
