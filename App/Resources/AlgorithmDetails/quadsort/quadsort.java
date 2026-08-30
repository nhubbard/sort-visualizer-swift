import java.util.Arrays;

public class quadsort {
  // -- Fixed-size sorting networks --------------------------------------------------------------

  static void swapTwo(int[] arr, int start) {
    if (arr[start] > arr[start + 1]) {
      swap2(arr, start, start + 1);
    }
  }

  static void swapThree(int[] arr, int start) {
    if (arr[start] > arr[start + 1]) {
      if (arr[start] <= arr[start + 2]) {
        swap2(arr, start, start + 1);
      } else if (arr[start + 1] > arr[start + 2]) {
        swap2(arr, start, start + 2);
      } else {
        int temp = arr[start];
        arr[start] = arr[start + 1];
        arr[start + 1] = arr[start + 2];
        arr[start + 2] = temp;
      }
    } else if (arr[start + 1] > arr[start + 2]) {
      if (arr[start] > arr[start + 2]) {
        int temp = arr[start + 2];
        arr[start + 2] = arr[start + 1];
        arr[start + 1] = arr[start];
        arr[start] = temp;
      } else {
        swap2(arr, start + 2, start + 1);
      }
    }
  }

  static void swapFour(int[] arr, int start) {
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
          int temp = arr[start + 1];
          arr[start + 1] = arr[start + 2];
          arr[start + 2] = arr[start + 3];
          arr[start + 3] = temp;
        }
      } else if (arr[start] > arr[start + 3]) {
        swap2(arr, start + 1, start + 3);
        swap2(arr, start, start + 2);
      } else if (arr[start + 1] <= arr[start + 3]) {
        int temp = arr[start + 1];
        arr[start + 1] = arr[start];
        arr[start] = arr[start + 2];
        arr[start + 2] = temp;
      } else {
        int temp = arr[start + 1];
        arr[start + 1] = arr[start];
        arr[start] = arr[start + 2];
        arr[start + 2] = arr[start + 3];
        arr[start + 3] = temp;
      }
    }
  }

  // Inserts the element at end[0] into the already-sorted run [start, end[0] - 1] (always exactly
  // 4 elements: swapFour runs immediately before every call site). `end` is a length-1 array used
  // as an out-parameter, matching the original's `inout Int`.
  static void swapFive(int[] arr, int start, int[] end) {
    end[0] = start + 4;
    int pta = end[0];
    end[0] += 1;
    int ptt = pta;
    pta -= 1;

    if (arr[pta] > arr[ptt]) {
      int key = arr[ptt];
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

  // Same shift logic as swapFive, one neighbor further out (checks pta - 2 first).
  static void tailSwapEight(int[] arr, int start, int[] end) {
    int pta = end[0];
    end[0] += 1;
    int ptt = pta;
    pta -= 1;

    if (arr[pta] > arr[ptt]) {
      int key = arr[ptt];
      arr[ptt] = arr[pta];
      ptt -= 1;
      pta -= 1;

      if (arr[pta - 2] > key) {
        for (int i = 0; i < 3; i++) {
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

  static void swapSix(int[] arr, int start, int[] end) {
    swapFive(arr, start, end);
    tailSwapEight(arr, start, end);
  }

  static void swapSeven(int[] arr, int start, int[] end) {
    swapSix(arr, start, end);
    tailSwapEight(arr, start, end);
  }

  static void swapEight(int[] arr, int start, int[] end) {
    swapSeven(arr, start, end);
    tailSwapEight(arr, start, end);
  }

  // ~4 items: one of the fixed sorting networks above. 5+: an unguarded insertion sort --
  // swapFive/Six/Seven/Eight handle the first 5-8 elements by hand, then a binary-search insertion
  // (the `while (top > 1)` loop) places everything past index 8.
  static void tailSwap(int[] arr, int start, int nmemb) {
    int[] end = {0};
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
    int offset = 8;

    while (offset < nmemb) {
      int top = offset;
      offset += 1;
      int pta = end[0];
      end[0] += 1;
      int ptt = pta;
      pta -= 1;

      if (arr[pta] <= arr[ptt]) {
        continue;
      }

      int temp = arr[ptt];
      while (top > 1) {
        int mid = top / 2;
        if (arr[pta - mid] > temp) {
          pta -= mid;
        }
        top -= mid;
      }

      int i = ptt;
      while (i > pta) {
        arr[i] = arr[i - 1];
        i -= 1;
      }
      arr[pta] = temp;
    }
  }

  // -- Parity merges (merge 4+4 into 8, or 8+8 into 16, tracking both ends at once) ---------------

  // Merges the two 4-element runs at [start, start+4) and [start+4, start+8) from the main array
  // into dest (a scratch buffer), working from both ends toward the middle simultaneously --
  // forward comparisons use <= and backward ones use >, which is what keeps this stable.
  static void parityMerge4(int[] arr, int start, int[] dest, int auxOffset) {
    int auxP = auxOffset;
    int ptl = start;
    int ptr = start + 4;

    for (int i = 0; i < 3; i++) {
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

    for (int i = 0; i < 3; i++) {
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

  // Same shape as parityMerge4, one level up: merges two 8-element runs from `from` (a scratch
  // buffer) back into the main array.
  static void parityMerge8(int[] arr, int[] from, int start) {
    int mainP = start;
    int ptl = 0;
    int ptr = 8;

    for (int i = 0; i < 7; i++) {
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

    for (int i = 0; i < 7; i++) {
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

  // Merges four already-sorted 4-element runs (16 elements total) via two parityMerge4 passes into
  // aux, then one parityMerge8 pass back -- but only if they aren't already sorted, which the
  // three comparisons below check cheaply.
  static void parityMerge16(int[] arr, int start, int[] aux) {
    if (arr[start + 3] <= arr[start + 4]
        && arr[start + 7] <= arr[start + 8]
        && arr[start + 11] <= arr[start + 12]) {
      return;
    }

    parityMerge4(arr, start, aux, 0);
    parityMerge4(arr, start + 8, aux, 8);
    parityMerge8(arr, aux, start);
  }

  // -- Bottom-up tail merge (arrays under 256, and quadMerge's own fallback tail) -----------------

  static void partialBackwardMerge(int[] arr, int[] aux, int start, int nmemb, int block) {
    int m = start + block;
    int e = start + nmemb - 1;
    int r = m;
    m -= 1;

    if (arr[m] <= arr[r]) {
      return;
    }
    while (arr[m] <= arr[e]) {
      e -= 1;
    }

    for (int i = r; i < r + (e - m); i++) {
      aux[i - r] = arr[i];
    }

    int s = e - r;
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

  // Bottom-up merge pass: doubles `block` each round, merging every adjacent pair of runs at the
  // current width via partialBackwardMerge, until `block` covers the whole [start, start + nmemb)
  // range.
  static void tailMerge(int[] arr, int[] aux, int start, int nmemb, int blockIn) {
    int block = blockIn;
    int pte = start + nmemb;

    while (block < nmemb) {
      int pta = start;
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

  // -- Quad merge (arrays 256 and up) -------------------------------------------------------------

  static int forwardMergeRead(int[] arr, int[] aux, boolean toAux, int i) {
    return toAux ? arr[i] : aux[i];
  }

  static void forwardMergeWrite(int[] arr, int[] aux, boolean toAux, int i, int value) {
    if (toAux) {
      aux[i] = value;
    } else {
      arr[i] = value;
    }
  }

  // Merges main-array run [start, start+block) with aux-buffer run starting at auxStart (or vice
  // versa, controlled by toAux) into the other side.
  static void forwardMerge(
      int[] arr, int[] aux, int start, int auxStart, int block, boolean toAux) {
    int mergeP = toAux ? auxStart : start;
    int l = toAux ? start : auxStart;
    int r = toAux ? (start + block) : (auxStart + block);
    int m = r;
    int e = r + block;

    if (forwardMergeRead(arr, aux, toAux, r - 1) <= forwardMergeRead(arr, aux, toAux, e - 1)) {
      while (l < m) {
        if (forwardMergeRead(arr, aux, toAux, l) <= forwardMergeRead(arr, aux, toAux, r)) {
          forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, l));
          mergeP += 1;
          l += 1;
        } else {
          forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, r));
          mergeP += 1;
          r += 1;
        }
      }
      while (r < e) {
        forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, r));
        mergeP += 1;
        r += 1;
      }
    } else {
      while (r < e) {
        if (forwardMergeRead(arr, aux, toAux, l) > forwardMergeRead(arr, aux, toAux, r)) {
          forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, r));
          mergeP += 1;
          r += 1;
        } else {
          forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, l));
          mergeP += 1;
          l += 1;
        }
      }
      while (l < m) {
        forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, l));
        mergeP += 1;
        l += 1;
      }
    }
  }

  // Merges 4 adjacent `block`-sized runs ([start, start+4*block)) into one sorted run, via up to
  // 3 already-sorted fast-path checks that skip straight to a smaller merge -- or none at all --
  // when consecutive runs are already in order.
  static void quadMergeBlock(int[] arr, int start, int[] aux, int block) {
    int blockX2 = block * 2;
    int cMax = start + block;

    if (arr[cMax - 1] <= arr[cMax]) {
      cMax += blockX2;

      if (arr[cMax - 1] <= arr[cMax]) {
        cMax -= block;

        if (arr[cMax - 1] <= arr[cMax]) {
          return;
        }

        int pts = 0;
        int c = start;
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

      int pts = 0;
      int c = start;
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

  // Quad-merges the entire [start, start+nmemb) range, doubling `block` by 4 each round; falls
  // back to tailMerge for whatever doesn't divide evenly into quad blocks at the current size,
  // and again at the very end for the final, coarsest remainder.
  static void quadMerge(int[] arr, int[] aux, int start, int nmemb, int blockIn) {
    int pte = start + nmemb;
    int block = blockIn * 4;

    while (block * 2 <= nmemb) {
      int pta = start;
      do {
        quadMergeBlock(arr, pta, aux, block / 4);
        pta += block;
      } while (pta + block <= pte);
      tailMerge(arr, aux, pta, pte - pta, block / 4);
      block *= 4;
    }
    tailMerge(arr, aux, start, nmemb, block / 4);
  }

  // -- Pre-sort pass
  // -------------------------------------------------------------------------------

  // Pre-sorting pass: a 4-item sorting network applied across the whole range, with a side
  // detector for strictly-decreasing runs -- reversed in place rather than merged, since a
  // reversal is cheaper and exactly reproduces a decreasing run's sorted order. If the *entire*
  // range turns out strictly decreasing, one reversal finishes the sort outright (returns 1);
  // otherwise this finishes with parity-merge passes over what's left (returns 0, meaning the
  // caller still has more merging to do).
  static int quadSwap(int[] arr, int start, int nmemb) {
    int[] swapBuf = new int[16];
    int pta = start;
    int count = nmemb / 4;
    int pts = 0;

    swapper:
    while (count > 0) {
      count -= 1;

      // innerA -- runs exactly once per outer iteration: either falls into innerB (a strictly
      // descending run of at least 2 quad-blocks was detected) or finishes this block's own
      // 4-item network and moves on.
      innerA:
      while (true) {
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
              int temp = arr[pta + 1];
              arr[pta + 1] = arr[pta + 2];
              arr[pta + 2] = arr[pta + 3];
              arr[pta + 3] = temp;
            }
          } else if (arr[pta] > arr[pta + 3]) {
            swap2(arr, pta + 1, pta + 3);
            swap2(arr, pta, pta + 2);
          } else if (arr[pta + 1] <= arr[pta + 3]) {
            int temp = arr[pta + 1];
            arr[pta + 1] = arr[pta];
            arr[pta] = arr[pta + 2];
            arr[pta + 2] = temp;
          } else {
            int temp = arr[pta + 1];
            arr[pta + 1] = arr[pta];
            arr[pta] = arr[pta + 2];
            arr[pta + 2] = arr[pta + 3];
            arr[pta + 3] = temp;
          }
        }
        pta += 4;
        continue swapper;
      }

      innerB:
      while (true) {
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
                int temp = arr[pta + 1];
                arr[pta + 1] = arr[pta + 2];
                arr[pta + 2] = arr[pta + 3];
                arr[pta + 3] = temp;
              }
            } else if (arr[pta] > arr[pta + 3]) {
              swap2(arr, pta, pta + 2);
              swap2(arr, pta + 1, pta + 3);
            } else if (arr[pta + 1] <= arr[pta + 3]) {
              int temp = arr[pta];
              arr[pta] = arr[pta + 2];
              arr[pta + 2] = arr[pta + 1];
              arr[pta + 1] = temp;
            } else {
              int temp = arr[pta];
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

        if (pts == start) {
          int remainder = nmemb % 4;
          if (remainder == 3) {
            remainder = (arr[pta + 1] > arr[pta + 2]) ? 2 : -1;
          }
          if (remainder == 2) {
            remainder = (arr[pta] > arr[pta + 1]) ? 1 : -1;
          }
          if (remainder == 1) {
            remainder = (arr[pta - 1] > arr[pta]) ? 0 : -1;
          }
          if (remainder == 0) {
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
    count = nmemb / 16;
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

  // -- Small helpers ---------------------------------------------------------------------------

  static void swap2(int[] arr, int i, int j) {
    int t = arr[i];
    arr[i] = arr[j];
    arr[j] = t;
  }

  static void reverseInclusive(int[] arr, int lo, int hi) {
    while (lo < hi) {
      swap2(arr, lo, hi);
      lo++;
      hi--;
    }
  }

  // -- Entry point -----------------------------------------------------------------------------

  // Top-level dispatch by size: under 16 is a plain tailSwap; under 256 pre-sorts via quadSwap
  // then finishes with tailMerge; 256 and up finishes with the full quadMerge pass instead.
  public static void sort(int[] arr, int n) {
    if (n < 16) {
      tailSwap(arr, 0, n);
    } else if (n < 256) {
      if (quadSwap(arr, 0, n) == 0) {
        int[] buffer = new int[128];
        tailMerge(arr, buffer, 0, n, 16);
      }
    } else {
      if (quadSwap(arr, 0, n) == 0) {
        int[] buffer = new int[n / 2];
        quadMerge(arr, buffer, 0, n, 16);
      }
    }
  }

  public static void main(String[] args) {
    int[] array =
        new int[] {
          55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51,
          66, 29, 44, 12, 90, 1, 58, 33, 71, 19, 60, 45, 27, 82, 6, 95, 38, 63, 9, 50
        };
    sort(array, array.length);
    System.out.println(Arrays.toString(array));
  }
}
