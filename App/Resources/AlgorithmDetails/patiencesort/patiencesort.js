class MinHeap {
  constructor() {
    this.storage = [];
  }

  get isEmpty() {
    return this.storage.length === 0;
  }

  push(entry) {
    this.storage.push(entry);
    let i = this.storage.length - 1;
    while (i > 0) {
      const parent = (i - 1) >> 1;
      if (this.storage[parent].top <= this.storage[i].top) break;
      [this.storage[parent], this.storage[i]] = [
        this.storage[i],
        this.storage[parent],
      ];
      i = parent;
    }
  }

  popMin() {
    const result = this.storage[0];
    const last = this.storage.pop();
    if (this.storage.length > 0) {
      this.storage[0] = last;
      let i = 0;
      while (true) {
        const left = 2 * i + 1;
        const right = 2 * i + 2;
        let smallest = i;
        if (
          left < this.storage.length &&
          this.storage[left].top < this.storage[smallest].top
        )
          smallest = left;
        if (
          right < this.storage.length &&
          this.storage[right].top < this.storage[smallest].top
        )
          smallest = right;
        if (smallest === i) break;
        [this.storage[i], this.storage[smallest]] = [
          this.storage[smallest],
          this.storage[i],
        ];
        i = smallest;
      }
    }
    return result;
  }
}

function sort(arr) {
  const n = arr.length;
  const piles = [];
  const tops = [];

  for (const x of arr) {
    // binary search: leftmost pile whose top is >= x
    let lo = 0;
    let hi = piles.length;
    while (lo < hi) {
      const mid = (lo + hi) >> 1;
      if (tops[mid] >= x) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    if (lo === piles.length) {
      piles.push([x]);
      tops.push(x);
    } else {
      piles[lo].push(x);
      tops[lo] = x;
    }
  }

  const heap = new MinHeap();
  for (let i = 0; i < piles.length; i++) {
    heap.push({ top: tops[i], pileIndex: i });
  }

  const result = [];
  while (!heap.isEmpty) {
    const entry = heap.popMin();
    const value = piles[entry.pileIndex].pop();
    result.push(value);
    if (piles[entry.pileIndex].length > 0) {
      heap.push({
        top: piles[entry.pileIndex][piles[entry.pileIndex].length - 1],
        pileIndex: entry.pileIndex,
      });
    }
  }

  for (let i = 0; i < n; i++) {
    arr[i] = result[i];
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
