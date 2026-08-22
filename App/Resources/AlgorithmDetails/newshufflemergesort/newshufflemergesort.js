function multiSwap(arr, i, j, length) {
  for (var k = 0; k < length; k++) {
    var t = arr[i + k];
    arr[i + k] = arr[j + k];
    arr[j + k] = t;
  }
}

function rotate(arr, mid, leftLen, rightLen) {
  while (leftLen > 0 && rightLen > 0) {
    if (leftLen > rightLen) {
      multiSwap(arr, mid - rightLen, mid, rightLen);
      mid -= rightLen;
      leftLen -= rightLen;
    } else {
      multiSwap(arr, mid - leftLen, mid, leftLen);
      mid += leftLen;
      rightLen -= leftLen;
    }
  }
}

// Perfect-shuffle a chunk of `size - 1` elements by following the cycles of i -> i*2 mod size.
function shuffleBlock(arr, start, size) {
  var i = 1;
  while (i < size) {
    var val = arr[start + i - 1];
    var j = (i * 2) % size;
    while (j !== i) {
      var nextVal = arr[start + j - 1];
      arr[start + j - 1] = val;
      val = nextVal;
      j = (j * 2) % size;
    }
    arr[start + i - 1] = val;
    i *= 3;
  }
}

// A single riffle shuffle only closes into clean cycles at power-of-three sizes, so shuffle in
// power-of-three chunks and rotate the next chunk's tail into place before each one.
function shuffle(arr, start, end) {
  while (end - start > 1) {
    var half = Math.floor((end - start) / 2);
    var chunk = 1;
    while (chunk * 3 - 1 <= 2 * half) {
      chunk *= 3;
    }
    var tail = Math.floor((chunk - 1) / 2);
    rotate(arr, start + half, half - tail, tail);
    shuffleBlock(arr, start, chunk);
    start += chunk - 1;
  }
}

function rotateShuffledEqual(arr, i, j, size) {
  var k = 0;
  while (k < size) {
    var t = arr[i + k];
    arr[i + k] = arr[j + k];
    arr[j + k] = t;
    k += 2;
  }
}

function rotateShuffled(arr, mid, leftLen, rightLen) {
  while (leftLen > 0 && rightLen > 0) {
    if (leftLen > rightLen) {
      rotateShuffledEqual(arr, mid - rightLen, mid, rightLen);
      mid -= rightLen;
      leftLen -= rightLen;
    } else {
      rotateShuffledEqual(arr, mid - leftLen, mid, leftLen);
      mid += leftLen;
      rightLen -= leftLen;
    }
  }
}

function rotateShuffledOuter(arr, mid, leftLen, rightLen) {
  if (leftLen > rightLen) {
    rotateShuffledEqual(arr, mid - rightLen, mid + 1, rightLen);
    mid -= rightLen;
    leftLen -= rightLen;
    rotateShuffled(arr, mid, leftLen, rightLen);
  } else {
    rotateShuffledEqual(arr, mid - leftLen, mid + 1, leftLen);
    mid += leftLen + 1;
    rightLen -= leftLen;
    rotateShuffled(arr, mid, leftLen, rightLen);
  }
}

// The inverse of shuffleBlock: walks the same cycles, writing each value one step backward.
function unshuffleBlock(arr, start, size) {
  var i = 1;
  while (i < size) {
    var prev = i;
    var val = arr[start + i - 1];
    var j = (i * 2) % size;
    while (j !== i) {
      arr[start + prev - 1] = arr[start + j - 1];
      prev = j;
      j = (j * 2) % size;
    }
    arr[start + prev - 1] = val;
    i *= 3;
  }
}

function unshuffle(arr, start, end) {
  while (end - start > 1) {
    var half = Math.floor((end - start) / 2);
    var chunk = 1;
    while (chunk * 3 - 1 <= 2 * half) {
      chunk *= 3;
    }
    var tail = Math.floor((chunk - 1) / 2);
    rotateShuffledOuter(arr, start + 2 * tail, 2 * tail, 2 * half - 2 * tail);
    unshuffleBlock(arr, start, chunk);
    start += chunk - 1;
  }
}

function compare3(arr, i, j) {
  if (arr[i] < arr[j]) return -1;
  return arr[i] === arr[j] ? 0 : 1;
}

// Scans the shuffled (interleaved) range one adjacent pair at a time. A pair already in order
// just advances the scan; a stretch of same-side elements gets un-shuffled back into two short
// plain runs and rotated into its final position.
function mergeUp(arr, start, end, fromLeft) {
  var i = start;
  var j = i + 1;
  while (j < end) {
    var cmp = compare3(arr, i, j);
    if (cmp === -1 || (!fromLeft && cmp === 0)) {
      i += 1;
      if (i === j) {
        j += 1;
        fromLeft = !fromLeft;
      }
    } else if (end - j === 1) {
      rotate(arr, j, j - i, 1);
      break;
    } else {
      var run = 0;
      if (fromLeft) {
        while (j + 2 * run < end && compare3(arr, j + 2 * run, i) !== 1)
          run += 1;
      } else {
        while (j + 2 * run < end && compare3(arr, j + 2 * run, i) === -1)
          run += 1;
      }
      j -= 1;
      unshuffle(arr, j, j + 2 * run);
      rotate(arr, j, j - i, run);
      i += run + 1;
      j += 2 * run + 1;
    }
  }
}

function merge(arr, start, mid, end) {
  if (mid - start <= end - mid) {
    shuffle(arr, start, end);
    mergeUp(arr, start, end, true);
  } else {
    shuffle(arr, start + 1, end);
    mergeUp(arr, start, end, false);
  }
}

function ceilPow2(x) {
  x -= 1;
  for (var shift = 16; shift > 0; shift >>= 1) {
    x |= x >> shift;
  }
  return x + 1;
}

function sort(arr) {
  var n = arr.length;
  if (n < 2) return;

  var subarrayCount = ceilPow2(n);
  while (subarrayCount > 1) {
    var i = 0;
    while (i < subarrayCount) {
      var lo = Math.floor((n * i) / subarrayCount);
      var mid = Math.floor((n * (i + 1)) / subarrayCount);
      var hi = Math.floor((n * (i + 2)) / subarrayCount);
      merge(arr, lo, mid, hi);
      i += 2;
    }
    subarrayCount >>= 1;
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
