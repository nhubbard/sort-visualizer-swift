function sort(arr) {
  const n = arr.length;
  if (n <= 1) {
    return;
  }

  const EMPTY = Number.MIN_SAFE_INTEGER;
  let capacity = 0;
  let slots = [];
  // Physical `slots` index of each placed element, ascending by both position and value.
  let positions = [];

  function rebalance() {
    const count = positions.length;
    const newCapacity = Math.max(2, count * 2);
    const newSlots = new Array(newCapacity).fill(EMPTY);
    const newPositions = [];
    for (let i = 0; i < count; i++) {
      const pos = positions[i];
      const newPos = i * 2;
      newSlots[newPos] = slots[pos];
      newPositions.push(newPos);
    }
    slots = newSlots;
    positions = newPositions;
    capacity = newCapacity;
  }

  function insert(value) {
    if (positions.length === capacity) {
      rebalance();
    }

    // Upper-bound binary search: first slot whose value is strictly greater than `value`.
    let lo = 0;
    let hi = positions.length;
    while (lo < hi) {
      const mid = Math.floor((lo + hi) / 2);
      if (slots[positions[mid]] > value) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    const k = lo;
    const targetPos = k === 0 ? 0 : positions[k - 1] + 1;

    if (!(targetPos === capacity || slots[targetPos] !== EMPTY)) {
      slots[targetPos] = value;
      positions.splice(k, 0, targetPos);
      return;
    }

    // Either targetPos is already occupied, or targetPos === capacity (new maximum, no room
    // left of the structure's end). Search BOTH directions for the nearest gap and shift
    // whichever side is closer.
    let leftGap = targetPos - 1;
    while (leftGap >= 0 && slots[leftGap] !== EMPTY) {
      leftGap--;
    }
    let rightGap = targetPos;
    while (rightGap < capacity && slots[rightGap] !== EMPTY) {
      rightGap++;
    }
    const leftDistance = leftGap >= 0 ? targetPos - leftGap : Infinity;
    const rightDistance = rightGap < capacity ? rightGap - targetPos : Infinity;

    if (rightDistance <= leftDistance) {
      let i = rightGap;
      while (i > targetPos) {
        slots[i] = slots[i - 1];
        i--;
      }
      for (let idx = k; idx < k + (rightGap - targetPos); idx++) {
        positions[idx]++;
      }
      slots[targetPos] = value;
      positions.splice(k, 0, targetPos);
    } else {
      const shiftCount = targetPos - 1 - leftGap;
      let i = leftGap;
      while (i < targetPos - 1) {
        slots[i] = slots[i + 1];
        i++;
      }
      for (let idx = k - shiftCount; idx < k; idx++) {
        positions[idx]--;
      }
      slots[targetPos - 1] = value;
      positions.splice(k, 0, targetPos - 1);
    }
  }

  for (const v of arr) {
    insert(v);
  }

  const result = new Array(n);
  for (let i = 0; i < positions.length; i++) {
    result[i] = slots[positions[i]];
  }
  for (let i = 0; i < n; i++) {
    arr[i] = result[i];
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
