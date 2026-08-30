function swap2(arr, i, j) {
  const t = arr[i];
  arr[i] = arr[j];
  arr[j] = t;
}

function reverseInclusive(arr, lo, hi) {
  while (lo < hi) {
    swap2(arr, lo, hi);
    lo++;
    hi--;
  }
}

// -- Fixed-size sorting networks ----------------------------------------------------------------

function swapTwo(arr, start) {
  if (arr[start] > arr[start + 1]) {
    swap2(arr, start, start + 1);
  }
}

function swapThree(arr, start) {
  if (arr[start] > arr[start + 1]) {
    if (arr[start] <= arr[start + 2]) {
      swap2(arr, start, start + 1);
    } else if (arr[start + 1] > arr[start + 2]) {
      swap2(arr, start, start + 2);
    } else {
      const temp = arr[start];
      arr[start] = arr[start + 1];
      arr[start + 1] = arr[start + 2];
      arr[start + 2] = temp;
    }
  } else if (arr[start + 1] > arr[start + 2]) {
    if (arr[start] > arr[start + 2]) {
      const temp = arr[start + 2];
      arr[start + 2] = arr[start + 1];
      arr[start + 1] = arr[start];
      arr[start] = temp;
    } else {
      swap2(arr, start + 2, start + 1);
    }
  }
}

function swapFour(arr, start) {
  if (arr[start] > arr[start + 1]) {
    swap2(arr, start, start + 1);
  }
  if (arr[start + 2] > arr[start + 3]) {
    swap2(arr, start + 2, start + 3);
  }
  if (arr[start + 1] > arr[start + 2]) {
    if (arr[start] <= arr[start + 2]) {
      if (arr[start + 1] <= arr[start + 3]) {
        swap2(arr, start + 1, start + 2);
      } else {
        const temp = arr[start + 1];
        arr[start + 1] = arr[start + 2];
        arr[start + 2] = arr[start + 3];
        arr[start + 3] = temp;
      }
    } else if (arr[start] > arr[start + 3]) {
      swap2(arr, start + 1, start + 3);
      swap2(arr, start, start + 2);
    } else if (arr[start + 1] <= arr[start + 3]) {
      const temp = arr[start + 1];
      arr[start + 1] = arr[start];
      arr[start] = arr[start + 2];
      arr[start + 2] = temp;
    } else {
      const temp = arr[start + 1];
      arr[start + 1] = arr[start];
      arr[start] = arr[start + 2];
      arr[start + 2] = arr[start + 3];
      arr[start + 3] = temp;
    }
  }
}

// `end` is a length-1 array used as an out-parameter, matching the original's `inout Int`.
function swapFive(arr, start, end) {
  end[0] = start + 4;
  let pta = end[0];
  end[0] += 1;
  let ptt = pta;
  pta -= 1;

  if (arr[pta] > arr[ptt]) {
    const key = arr[ptt];
    arr[ptt] = arr[pta];
    ptt -= 1;
    pta -= 1;

    if (pta > start && arr[pta - 1] > key) {
      arr[ptt] = arr[pta];
      ptt -= 1;
      pta -= 1;
      arr[ptt] = arr[pta];
      ptt -= 1;
      pta -= 1;
    }

    if (pta >= start && arr[pta] > key) {
      arr[ptt] = arr[pta];
      ptt -= 1;
      pta -= 1;
    }

    arr[ptt] = key;
  }
}

function tailSwapEight(arr, start, end) {
  let pta = end[0];
  end[0] += 1;
  let ptt = pta;
  pta -= 1;

  if (arr[pta] > arr[ptt]) {
    const key = arr[ptt];
    arr[ptt] = arr[pta];
    ptt -= 1;
    pta -= 1;

    if (arr[pta - 2] > key) {
      for (let i = 0; i < 3; i++) {
        arr[ptt] = arr[pta];
        ptt -= 1;
        pta -= 1;
      }
    }

    if (pta > start && arr[pta - 1] > key) {
      arr[ptt] = arr[pta];
      ptt -= 1;
      pta -= 1;
      arr[ptt] = arr[pta];
      ptt -= 1;
      pta -= 1;
    }

    if (pta >= start && arr[pta] > key) {
      arr[ptt] = arr[pta];
      ptt -= 1;
      pta -= 1;
    }

    arr[ptt] = key;
  }
}

function swapSix(arr, start, end) {
  swapFive(arr, start, end);
  tailSwapEight(arr, start, end);
}

function swapSeven(arr, start, end) {
  swapSix(arr, start, end);
  tailSwapEight(arr, start, end);
}

function swapEight(arr, start, end) {
  swapSeven(arr, start, end);
  tailSwapEight(arr, start, end);
}

// ~4 items: one of the fixed sorting networks above. 5+: an unguarded insertion sort --
// swapFive/Six/Seven/Eight handle the first 5-8 elements by hand, then a binary-search insertion
// (the `while (top > 1)` loop) places everything past index 8.
function tailSwap(arr, start, nmemb) {
  const end = [0];
  switch (nmemb) {
    case 0:
    case 1:
      return;
    case 2:
      swapTwo(arr, start);
      return;
    case 3:
      swapThree(arr, start);
      return;
    case 4:
      swapFour(arr, start);
      return;
    case 5:
      swapFour(arr, start);
      swapFive(arr, start, end);
      return;
    case 6:
      swapFour(arr, start);
      swapSix(arr, start, end);
      return;
    case 7:
      swapFour(arr, start);
      swapSeven(arr, start, end);
      return;
    case 8:
      swapFour(arr, start);
      swapEight(arr, start, end);
      return;
    default:
      break;
  }

  swapFour(arr, start);
  swapEight(arr, start, end);
  end[0] = start + 8;
  let offset = 8;

  while (offset < nmemb) {
    let top = offset;
    offset += 1;
    let pta = end[0];
    end[0] += 1;
    const ptt = pta;
    pta -= 1;

    if (arr[pta] <= arr[ptt]) {
      continue;
    }

    const temp = arr[ptt];
    while (top > 1) {
      const mid = Math.floor(top / 2);
      if (arr[pta - mid] > temp) {
        pta -= mid;
      }
      top -= mid;
    }

    let i = ptt;
    while (i > pta) {
      arr[i] = arr[i - 1];
      i -= 1;
    }
    arr[pta] = temp;
  }
}

// -- Parity merges --------------------------------------------------------------------------

function parityMerge4(arr, start, dest, auxOffset) {
  let auxP = auxOffset;
  let ptl = start;
  let ptr = start + 4;

  for (let i = 0; i < 3; i++) {
    if (arr[ptl] <= arr[ptr]) {
      dest[auxP] = arr[ptl];
      ptl += 1;
    } else {
      dest[auxP] = arr[ptr];
      ptr += 1;
    }
    auxP += 1;
  }
  if (arr[ptl] <= arr[ptr]) {
    dest[auxP] = arr[ptl];
  } else {
    dest[auxP] = arr[ptr];
  }

  ptl = start + 3;
  ptr = start + 7;
  auxP += 4;

  for (let i = 0; i < 3; i++) {
    if (arr[ptl] > arr[ptr]) {
      dest[auxP] = arr[ptl];
      ptl -= 1;
    } else {
      dest[auxP] = arr[ptr];
      ptr -= 1;
    }
    auxP -= 1;
  }
  if (arr[ptl] > arr[ptr]) {
    dest[auxP] = arr[ptl];
  } else {
    dest[auxP] = arr[ptr];
  }
}

function parityMerge8(arr, from, start) {
  let mainP = start;
  let ptl = 0;
  let ptr = 8;

  for (let i = 0; i < 7; i++) {
    if (from[ptl] <= from[ptr]) {
      arr[mainP] = from[ptl];
      ptl += 1;
    } else {
      arr[mainP] = from[ptr];
      ptr += 1;
    }
    mainP += 1;
  }
  if (from[ptl] <= from[ptr]) {
    arr[mainP] = from[ptl];
  } else {
    arr[mainP] = from[ptr];
  }

  ptl = 7;
  ptr = 15;
  mainP += 8;

  for (let i = 0; i < 7; i++) {
    if (from[ptl] > from[ptr]) {
      arr[mainP] = from[ptl];
      ptl -= 1;
    } else {
      arr[mainP] = from[ptr];
      ptr -= 1;
    }
    mainP -= 1;
  }
  if (from[ptl] > from[ptr]) {
    arr[mainP] = from[ptl];
  } else {
    arr[mainP] = from[ptr];
  }
}

function parityMerge16(arr, start, aux) {
  if (
    arr[start + 3] <= arr[start + 4] &&
    arr[start + 7] <= arr[start + 8] &&
    arr[start + 11] <= arr[start + 12]
  ) {
    return;
  }

  parityMerge4(arr, start, aux, 0);
  parityMerge4(arr, start + 8, aux, 8);
  parityMerge8(arr, aux, start);
}

// -- Bottom-up tail merge -----------------------------------------------------------------------

function partialBackwardMerge(arr, aux, start, nmemb, block) {
  let m = start + block;
  let e = start + nmemb - 1;
  const r = m;
  m -= 1;

  if (arr[m] <= arr[r]) {
    return;
  }
  while (arr[m] <= arr[e]) {
    e -= 1;
  }

  for (let i = r; i < r + (e - m); i++) {
    aux[i - r] = arr[i];
  }

  let s = e - r;
  arr[e] = arr[m];
  e -= 1;
  m -= 1;

  if (arr[start] <= aux[0]) {
    do {
      while (arr[m] > aux[s]) {
        arr[e] = arr[m];
        e -= 1;
        m -= 1;
      }
      arr[e] = aux[s];
      e -= 1;
      s -= 1;
    } while (s >= 0);
  } else {
    do {
      while (arr[m] <= aux[s]) {
        arr[e] = aux[s];
        e -= 1;
        s -= 1;
      }
      arr[e] = arr[m];
      e -= 1;
      m -= 1;
    } while (m >= start);
    do {
      arr[e] = aux[s];
      e -= 1;
      s -= 1;
    } while (s >= 0);
  }
}

function tailMerge(arr, aux, start, nmemb, blockIn) {
  let block = blockIn;
  const pte = start + nmemb;

  while (block < nmemb) {
    let pta = start;
    while (pta + block < pte) {
      if (pta + block * 2 < pte) {
        partialBackwardMerge(arr, aux, pta, block * 2, block);
        pta += block * 2;
        continue;
      }
      partialBackwardMerge(arr, aux, pta, pte - pta, block);
      break;
    }
    block *= 2;
  }
}

// -- Quad merge -----------------------------------------------------------------------------

function forwardMergeRead(arr, aux, toAux, i) {
  return toAux ? arr[i] : aux[i];
}

function forwardMergeWrite(arr, aux, toAux, i, value) {
  if (toAux) {
    aux[i] = value;
  } else {
    arr[i] = value;
  }
}

function forwardMerge(arr, aux, start, auxStart, block, toAux) {
  let mergeP = toAux ? auxStart : start;
  let l = toAux ? start : auxStart;
  let r = toAux ? start + block : auxStart + block;
  const m = r;
  const e = r + block;

  if (
    forwardMergeRead(arr, aux, toAux, r - 1) <=
    forwardMergeRead(arr, aux, toAux, e - 1)
  ) {
    while (l < m) {
      if (
        forwardMergeRead(arr, aux, toAux, l) <=
        forwardMergeRead(arr, aux, toAux, r)
      ) {
        forwardMergeWrite(
          arr,
          aux,
          toAux,
          mergeP,
          forwardMergeRead(arr, aux, toAux, l),
        );
        mergeP += 1;
        l += 1;
      } else {
        forwardMergeWrite(
          arr,
          aux,
          toAux,
          mergeP,
          forwardMergeRead(arr, aux, toAux, r),
        );
        mergeP += 1;
        r += 1;
      }
    }
    while (r < e) {
      forwardMergeWrite(
        arr,
        aux,
        toAux,
        mergeP,
        forwardMergeRead(arr, aux, toAux, r),
      );
      mergeP += 1;
      r += 1;
    }
  } else {
    while (r < e) {
      if (
        forwardMergeRead(arr, aux, toAux, l) >
        forwardMergeRead(arr, aux, toAux, r)
      ) {
        forwardMergeWrite(
          arr,
          aux,
          toAux,
          mergeP,
          forwardMergeRead(arr, aux, toAux, r),
        );
        mergeP += 1;
        r += 1;
      } else {
        forwardMergeWrite(
          arr,
          aux,
          toAux,
          mergeP,
          forwardMergeRead(arr, aux, toAux, l),
        );
        mergeP += 1;
        l += 1;
      }
    }
    while (l < m) {
      forwardMergeWrite(
        arr,
        aux,
        toAux,
        mergeP,
        forwardMergeRead(arr, aux, toAux, l),
      );
      mergeP += 1;
      l += 1;
    }
  }
}

function quadMergeBlock(arr, start, aux, block) {
  const blockX2 = block * 2;
  let cMax = start + block;

  if (arr[cMax - 1] <= arr[cMax]) {
    cMax += blockX2;

    if (arr[cMax - 1] <= arr[cMax]) {
      cMax -= block;

      if (arr[cMax - 1] <= arr[cMax]) {
        return;
      }

      let pts = 0;
      let c = start;
      do {
        aux[pts] = arr[c];
        c += 1;
        pts += 1;
      } while (c < cMax);

      cMax = c + blockX2;
      do {
        aux[pts] = arr[c];
        c += 1;
        pts += 1;
      } while (c < cMax);

      forwardMerge(arr, aux, start, 0, blockX2, false);
      return;
    }

    let pts = 0;
    let c = start;
    cMax = start + blockX2;
    do {
      aux[pts] = arr[c];
      c += 1;
      pts += 1;
    } while (c < cMax);
  } else {
    forwardMerge(arr, aux, start, 0, block, true);
  }

  forwardMerge(arr, aux, start + blockX2, blockX2, block, true);
  forwardMerge(arr, aux, start, 0, blockX2, false);
}

function quadMerge(arr, aux, start, nmemb, blockIn) {
  const pte = start + nmemb;
  let block = blockIn * 4;

  while (block * 2 <= nmemb) {
    let pta = start;
    do {
      quadMergeBlock(arr, pta, aux, Math.floor(block / 4));
      pta += block;
    } while (pta + block <= pte);
    tailMerge(arr, aux, pta, pte - pta, Math.floor(block / 4));
    block *= 4;
  }
  tailMerge(arr, aux, start, nmemb, Math.floor(block / 4));
}

// -- Pre-sort pass --------------------------------------------------------------------------

// Pre-sorting pass: a 4-item sorting network applied across the whole range, with a side
// detector for strictly-decreasing runs -- reversed in place rather than merged. If the *entire*
// range turns out strictly decreasing, one reversal finishes the sort outright (returns 1);
// otherwise this finishes with parity-merge passes over what's left (returns 0).
function quadSwap(arr, start, nmemb) {
  const swapBuf = new Array(16).fill(0);
  let pta = start;
  let count = Math.floor(nmemb / 4);
  let pts = 0;

  swapper: while (count > 0) {
    count -= 1;

    innerA: while (true) {
      if (arr[pta] > arr[pta + 1]) {
        if (arr[pta + 2] > arr[pta + 3]) {
          if (arr[pta + 1] > arr[pta + 2]) {
            pts = pta;
            pta += 4;
            break innerA;
          }
          swap2(arr, pta + 2, pta + 3);
        }
        swap2(arr, pta, pta + 1);
      } else if (arr[pta + 2] > arr[pta + 3]) {
        swap2(arr, pta + 2, pta + 3);
      }

      if (arr[pta + 1] > arr[pta + 2]) {
        if (arr[pta] <= arr[pta + 2]) {
          if (arr[pta + 1] <= arr[pta + 3]) {
            swap2(arr, pta + 1, pta + 2);
          } else {
            const temp = arr[pta + 1];
            arr[pta + 1] = arr[pta + 2];
            arr[pta + 2] = arr[pta + 3];
            arr[pta + 3] = temp;
          }
        } else if (arr[pta] > arr[pta + 3]) {
          swap2(arr, pta + 1, pta + 3);
          swap2(arr, pta, pta + 2);
        } else if (arr[pta + 1] <= arr[pta + 3]) {
          const temp = arr[pta + 1];
          arr[pta + 1] = arr[pta];
          arr[pta] = arr[pta + 2];
          arr[pta + 2] = temp;
        } else {
          const temp = arr[pta + 1];
          arr[pta + 1] = arr[pta];
          arr[pta] = arr[pta + 2];
          arr[pta + 2] = arr[pta + 3];
          arr[pta + 3] = temp;
        }
      }
      pta += 4;
      continue swapper;
    }

    innerB: while (true) {
      if (count > 0) {
        count -= 1;

        if (arr[pta] > arr[pta + 1]) {
          if (arr[pta + 2] > arr[pta + 3]) {
            if (arr[pta + 1] > arr[pta + 2]) {
              if (arr[pta - 1] > arr[pta]) {
                pta += 4;
                continue innerB;
              }
            }
            swap2(arr, pta + 2, pta + 3);
          }
          swap2(arr, pta, pta + 1);
        } else if (arr[pta + 2] > arr[pta + 3]) {
          swap2(arr, pta + 2, pta + 3);
        }

        if (arr[pta + 1] > arr[pta + 2]) {
          if (arr[pta] <= arr[pta + 2]) {
            if (arr[pta + 1] <= arr[pta + 3]) {
              swap2(arr, pta + 1, pta + 2);
            } else {
              const temp = arr[pta + 1];
              arr[pta + 1] = arr[pta + 2];
              arr[pta + 2] = arr[pta + 3];
              arr[pta + 3] = temp;
            }
          } else if (arr[pta] > arr[pta + 3]) {
            swap2(arr, pta, pta + 2);
            swap2(arr, pta + 1, pta + 3);
          } else if (arr[pta + 1] <= arr[pta + 3]) {
            const temp = arr[pta];
            arr[pta] = arr[pta + 2];
            arr[pta + 2] = arr[pta + 1];
            arr[pta + 1] = temp;
          } else {
            const temp = arr[pta];
            arr[pta] = arr[pta + 2];
            arr[pta + 2] = arr[pta + 3];
            arr[pta + 3] = arr[pta + 1];
            arr[pta + 1] = temp;
          }
        }

        reverseInclusive(arr, pts, pta - 1);
        pta += 4;
        continue swapper;
      }

      if (pts === start) {
        let remainder = nmemb % 4;
        if (remainder === 3) {
          remainder = arr[pta + 1] > arr[pta + 2] ? 2 : -1;
        }
        if (remainder === 2) {
          remainder = arr[pta] > arr[pta + 1] ? 1 : -1;
        }
        if (remainder === 1) {
          remainder = arr[pta - 1] > arr[pta] ? 0 : -1;
        }
        if (remainder === 0) {
          reverseInclusive(arr, pts, pts + nmemb - 1);
          return 1;
        }
      }

      reverseInclusive(arr, pts, pta - 1);
      break swapper;
    }
  }

  tailSwap(arr, pta, nmemb % 4);

  pta = start;
  count = Math.floor(nmemb / 16);
  while (count > 0) {
    count -= 1;
    parityMerge16(arr, pta, swapBuf);
    pta += 16;
  }

  if (nmemb % 16 > 4) {
    tailMerge(arr, swapBuf, pta, nmemb % 16, 4);
  }

  return 0;
}

// -- Entry point -----------------------------------------------------------------------------

// Top-level dispatch by size: under 16 is a plain tailSwap; under 256 pre-sorts via quadSwap then
// finishes with tailMerge; 256 and up finishes with the full quadMerge pass instead.
function sort(arr, n) {
  if (n < 16) {
    tailSwap(arr, 0, n);
  } else if (n < 256) {
    if (quadSwap(arr, 0, n) === 0) {
      const buffer = new Array(128).fill(0);
      tailMerge(arr, buffer, 0, n, 16);
    }
  } else {
    if (quadSwap(arr, 0, n) === 0) {
      const buffer = new Array(Math.floor(n / 2)).fill(0);
      quadMerge(arr, buffer, 0, n, 16);
    }
  }
}

var array = [
  55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51,
  66, 29, 44, 12, 90, 1, 58, 33, 71, 19, 60, 45, 27, 82, 6, 95, 38, 63, 9, 50,
];
sort(array, array.length);
console.log("[" + array.join(", ") + "]");
