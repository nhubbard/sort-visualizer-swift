function hyperfloor(n) {
  let power = 1;
  while (power * 2 <= n) power *= 2;
  return power;
}

function uncheckedInsertionSort(array, first, last) {
  let cur = first + 1;
  while (cur !== last) {
    if (array[cur] < array[cur - 1]) {
      const tmp = array[cur];
      let sift = cur;
      let sift1 = cur - 1;
      while (true) {
        array[sift] = array[sift1];
        sift--;
        if (sift === first) break;
        sift1--;
        if (tmp >= array[sift1]) break;
      }
      array[sift] = tmp;
    }
    cur++;
  }
}

function insertionSort(array, first, last) {
  if (first === last) return;
  uncheckedInsertionSort(array, first, last);
}

function poplarSift(array, firstIn, sizeIn) {
  let size = sizeIn;
  if (size < 2) return;
  let root = firstIn + (size - 1);
  let childRoot1 = root - 1;
  let childRoot2 = firstIn + (Math.floor(size / 2) - 1);
  while (true) {
    let maxRoot = root;
    if (array[maxRoot] < array[childRoot1]) maxRoot = childRoot1;
    if (array[maxRoot] < array[childRoot2]) maxRoot = childRoot2;
    if (maxRoot === root) return;
    [array[root], array[maxRoot]] = [array[maxRoot], array[root]];
    size = Math.floor(size / 2);
    if (size < 2) return;
    root = maxRoot;
    childRoot1 = root - 1;
    childRoot2 = maxRoot - (size - Math.floor(size / 2));
  }
}

function popHeapWithSize(array, first, last, sizeIn) {
  let size = sizeIn;
  let poplarSize = hyperfloor(size + 1) - 1;
  const lastRoot = last - 1;
  let bigger = lastRoot;
  let biggerSize = poplarSize;

  let it = first;
  while (true) {
    const root = it + poplarSize - 1;
    if (root === lastRoot) break;
    if (array[bigger] < array[root]) {
      bigger = root;
      biggerSize = poplarSize;
    }
    it = root + 1;
    size -= poplarSize;
    poplarSize = hyperfloor(size + 1) - 1;
  }

  if (bigger !== lastRoot) {
    [array[bigger], array[lastRoot]] = [array[lastRoot], array[bigger]];
    poplarSift(array, bigger - (biggerSize - 1), biggerSize);
  }
}

function makeHeap(array, first, last) {
  const size = last - first;
  if (size < 2) return;
  const smallPoplarSize = 15;
  if (size <= smallPoplarSize) {
    uncheckedInsertionSort(array, first, last);
    return;
  }

  let poplarLevel = 1;
  let it = first;
  let next = it + smallPoplarSize;
  while (true) {
    uncheckedInsertionSort(array, it, next);
    let poplarSize = smallPoplarSize;
    let i = (poplarLevel & -poplarLevel) >> 1;
    while (i !== 0) {
      it -= poplarSize;
      poplarSize = 2 * poplarSize + 1;
      if (it + poplarSize > last) break;
      poplarSift(array, it, poplarSize);
      next++;
      i >>= 1;
    }
    if (last - next <= smallPoplarSize) {
      insertionSort(array, next, last);
      return;
    }
    it = next;
    next += smallPoplarSize;
    poplarLevel++;
  }
}

function sortHeap(array, first, lastIn) {
  let last = lastIn;
  let size = last - first;
  if (size < 2) return;
  do {
    popHeapWithSize(array, first, last, size);
    last--;
    size--;
  } while (size > 1);
}

function sort(array) {
  const n = array.length;
  if (n <= 1) return;
  makeHeap(array, 0, n);
  sortHeap(array, 0, n);
}

const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log(`[${array.join(", ")}]`);
