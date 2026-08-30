import java.util.Arrays;

public class fluxsort {
  static final int FLUX_OUT = 24;

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

  // -- Parity merges --------------------------------------------------------------------------

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

  // -- Bottom-up tail merge -----------------------------------------------------------------------

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

  // -- Quad merge -----------------------------------------------------------------------------

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

  // -- Pre-sort pass --------------------------------------------------------------------------

  static int quadSwap(int[] arr, int start, int nmemb) {
    int[] swapBuf = new int[16];
    int pta = start;
    int count = nmemb / 4;
    int pts = 0;

    swapper:
    while (count > 0) {
      count -= 1;

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

  // -- Entry points into the embedded quadsort core ----------------------------------------------

  static void quadSortRange(int[] arr, int start, int length) {
    if (length < 16) {
      tailSwap(arr, start, length);
    } else if (length < 256) {
      if (quadSwap(arr, start, length) == 0) {
        int[] buffer = new int[128];
        tailMerge(arr, buffer, start, length, 16);
      }
    } else {
      if (quadSwap(arr, start, length) == 0) {
        int[] buffer = new int[length / 2];
        quadMerge(arr, buffer, start, length, 16);
      }
    }
  }

  static void quadSortRangeUsing(int[] arr, int[] swapBuf, int start, int length) {
    if (length < 16) {
      tailSwap(arr, start, length);
    } else if (length < 256) {
      if (quadSwap(arr, start, length) == 0) {
        tailMerge(arr, swapBuf, start, length, 16);
      }
    } else {
      if (quadSwap(arr, start, length) == 0) {
        quadMerge(arr, swapBuf, start, length, 16);
      }
    }
  }

  // -- FluxSort's own recursive partition --------------------------------------------------------

  static boolean fluxAnalyze(int[] arr, int nmemb) {
    int balance = 0;
    int pta = 0;
    int cnt = nmemb;
    while (true) {
      cnt -= 1;
      if (cnt <= 0) {
        break;
      }
      int left = pta;
      pta += 1;
      if (arr[left] > arr[pta]) {
        balance += 1;
      }
    }

    if (balance == 0) {
      return false;
    }

    if (balance == nmemb - 1) {
      reverseInclusive(arr, 0, nmemb - 1);
      return false;
    }

    if (balance <= nmemb / 6 || balance >= nmemb / 6 * 5) {
      quadSortRange(arr, 0, nmemb);
      return false;
    }

    return true;
  }

  static int mainGT(int[] arr, int[] swapBuf, boolean mainIsSwap, int a, int b) {
    if (mainIsSwap) {
      return swapBuf[a] > swapBuf[b] ? 1 : 0;
    }
    return arr[a] > arr[b] ? 1 : 0;
  }

  static int medianOfThree(int[] arr, int[] swapBuf, boolean mainIsSwap, int v0, int v1, int v2) {
    int val = mainGT(arr, swapBuf, mainIsSwap, v0, v1);
    int t0 = val;
    int t1 = val ^ 1;

    val = mainGT(arr, swapBuf, mainIsSwap, v0, v2);
    t0 += val;
    if (t0 == 1) {
      return v0;
    }

    val = mainGT(arr, swapBuf, mainIsSwap, v1, v2);
    t1 += val;
    return t1 == 1 ? v1 : v2;
  }

  static int medianOfFive(
      int[] arr, int[] swapBuf, boolean mainIsSwap, int v0, int v1, int v2, int v3, int v4) {
    int val = mainGT(arr, swapBuf, mainIsSwap, v0, v1);
    int t0 = val;
    int t1 = val ^ 1;

    val = mainGT(arr, swapBuf, mainIsSwap, v0, v2);
    t0 += val;
    int t2 = val ^ 1;

    val = mainGT(arr, swapBuf, mainIsSwap, v0, v3);
    t0 += val;
    int t3 = val ^ 1;

    val = mainGT(arr, swapBuf, mainIsSwap, v0, v4);
    t0 += val;

    if (t0 == 2) {
      return v0;
    }

    val = mainGT(arr, swapBuf, mainIsSwap, v1, v2);
    t1 += val;
    t2 += val ^ 1;

    val = mainGT(arr, swapBuf, mainIsSwap, v1, v3);
    t1 += val;
    t3 += val ^ 1;

    val = mainGT(arr, swapBuf, mainIsSwap, v1, v4);
    t1 += val;

    if (t1 == 2) {
      return v1;
    }

    val = mainGT(arr, swapBuf, mainIsSwap, v2, v3);
    t2 += val;
    t3 += val ^ 1;

    val = mainGT(arr, swapBuf, mainIsSwap, v2, v4);
    t2 += val;

    if (t2 == 2) {
      return v2;
    }

    val = mainGT(arr, swapBuf, mainIsSwap, v3, v4);
    t3 += val;

    return t3 == 2 ? v3 : v4;
  }

  static int medianOfNine(int[] arr, int[] swapBuf, boolean mainIsSwap, int ptx, int nmemb) {
    int div = nmemb / 16;
    int v0 = medianOfThree(arr, swapBuf, mainIsSwap, ptx + div * 2, ptx + div * 1, ptx + div * 4);
    int v1 = medianOfThree(arr, swapBuf, mainIsSwap, ptx + div * 8, ptx + div * 6, ptx + div * 10);
    int v2 =
        medianOfThree(arr, swapBuf, mainIsSwap, ptx + div * 14, ptx + div * 12, ptx + div * 15);
    return medianOfThree(arr, swapBuf, mainIsSwap, v0, v1, v2);
  }

  static int medianOfFifteen(int[] arr, int[] swapBuf, boolean mainIsSwap, int ptx, int nmemb) {
    int div = nmemb / 16;
    int v0 = medianOfThree(arr, swapBuf, mainIsSwap, ptx + div * 2, ptx + div * 1, ptx + div * 3);
    int v1 = medianOfThree(arr, swapBuf, mainIsSwap, ptx + div * 5, ptx + div * 4, ptx + div * 6);
    int v2 = medianOfThree(arr, swapBuf, mainIsSwap, ptx + div * 8, ptx + div * 7, ptx + div * 9);
    int v3 =
        medianOfThree(arr, swapBuf, mainIsSwap, ptx + div * 11, ptx + div * 10, ptx + div * 12);
    int v4 =
        medianOfThree(arr, swapBuf, mainIsSwap, ptx + div * 14, ptx + div * 13, ptx + div * 15);
    return medianOfFive(arr, swapBuf, mainIsSwap, v2, v0, v1, v3, v4);
  }

  static void fluxPartition(int[] arr, int[] swapBuf, boolean mainIsSwap, int start, int nmemb) {
    int ptxBase = mainIsSwap ? 0 : start;
    int medianIndex =
        nmemb > 1024
            ? medianOfFifteen(arr, swapBuf, mainIsSwap, ptxBase, nmemb)
            : medianOfNine(arr, swapBuf, mainIsSwap, ptxBase, nmemb);
    int piv = mainIsSwap ? swapBuf[medianIndex] : arr[medianIndex];

    int pte = ptxBase + nmemb;
    int pta = start;
    int pts = 0;
    int ptx = ptxBase;

    while (ptx < pte) {
      int value = mainIsSwap ? swapBuf[ptx] : arr[ptx];
      int val = value > piv ? 1 : 0;

      arr[pta] = value;
      pta += 1 - val;

      swapBuf[pts] = value;
      pts += val;

      ptx += 1;
    }

    int sSize = pts;
    int aSize = nmemb - sSize;

    if (aSize <= sSize / 16 || sSize <= FLUX_OUT) {
      for (int i = 0; i < sSize; i++) {
        arr[pta + i] = swapBuf[i];
      }
      quadSortRangeUsing(arr, swapBuf, pta, sSize);
    } else {
      fluxPartition(arr, swapBuf, true, pta, sSize);
    }

    if (sSize <= aSize / 16 || aSize <= FLUX_OUT) {
      quadSortRangeUsing(arr, swapBuf, start, aSize);
    } else {
      fluxPartition(arr, swapBuf, false, start, aSize);
    }
  }

  // -- Entry point
  // ---------------------------------------------------------------------------------

  public static void sort(int[] arr, int n) {
    if (n < 2) {
      return;
    }

    if (n < 32) {
      quadSortRange(arr, 0, n);
      return;
    }

    if (!fluxAnalyze(arr, n)) {
      return;
    }

    int[] swapBuf = new int[n];
    fluxPartition(arr, swapBuf, false, 0, n);
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
