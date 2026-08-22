import java.util.Arrays;

public class grailsort {
  public static void swap(int[] arr, int a, int b) {
    int t = arr[a];
    arr[a] = arr[b];
    arr[b] = t;
  }

  public static int compareValues(int a, int b) {
    return Integer.compare(a, b);
  }

  public static void multiSwap(int[] arr, int a, int b, int count) {
    for (int i = 0; i < count; i++) {
      swap(arr, a + i, b + i);
    }
  }

  public static void rotate(int[] arr, int pos, int lenA, int lenB) {
    while (lenA != 0 && lenB != 0) {
      if (lenA <= lenB) {
        multiSwap(arr, pos, pos + lenA, lenA);
        pos += lenA;
        lenB -= lenA;
      } else {
        multiSwap(arr, pos + (lenA - lenB), pos + lenA, lenB);
        lenA -= lenB;
      }
    }
  }

  public static void insertSort(int[] arr, int pos, int len) {
    for (int i = 1; i < len; i++) {
      int j = pos + i;
      while (j > pos && arr[j] < arr[j - 1]) {
        swap(arr, j, j - 1);
        j--;
      }
    }
  }

  public static int binSearch(int[] arr, int pos, int len, int keyPos, boolean isLeft) {
    int left = -1;
    int right = len;
    int key = arr[keyPos];
    while (left < right - 1) {
      int mid = left + (right - left) / 2;
      boolean cond = isLeft ? (arr[pos + mid] >= key) : (arr[pos + mid] > key);
      if (cond) {
        right = mid;
      } else {
        left = mid;
      }
    }
    return right;
  }

  public static int findKeys(int[] arr, int pos, int len, int numKeys) {
    int dist = 1;
    int foundKeys = 1;
    int firstKey = 0;
    while (dist < len && foundKeys < numKeys) {
      int loc = binSearch(arr, pos + firstKey, foundKeys, pos + dist, true);
      if (loc == foundKeys || arr[pos + dist] != arr[pos + firstKey + loc]) {
        rotate(arr, pos + firstKey, foundKeys, dist - (firstKey + foundKeys));
        firstKey = dist - foundKeys;
        rotate(arr, pos + (firstKey + loc), foundKeys - loc, 1);
        foundKeys++;
      }
      dist++;
    }
    rotate(arr, pos, firstKey, foundKeys);
    return foundKeys;
  }

  public static void mergeWithoutBuffer(int[] arr, int pos, int len1, int len2) {
    if (len1 == 0 || len2 == 0) {
      return;
    }
    if (len1 < len2) {
      while (len1 != 0) {
        int loc = binSearch(arr, pos + len1, len2, pos, true);
        if (loc != 0) {
          rotate(arr, pos, len1, loc);
          pos += loc;
          len2 -= loc;
        }
        if (len2 == 0) {
          break;
        }
        do {
          pos++;
          len1--;
        } while (len1 != 0 && arr[pos] <= arr[pos + len1]);
      }
    } else {
      while (len2 != 0) {
        int loc = binSearch(arr, pos, len1, pos + len1 + len2 - 1, false);
        if (loc != len1) {
          rotate(arr, pos + loc, len1 - loc, len2);
          len1 = loc;
        }
        if (len1 == 0) {
          break;
        }
        do {
          len2--;
        } while (len2 != 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1]);
      }
    }
  }

  public static void mergeLeft(int[] arr, int pos, int leftLen, int rightLen, int dist) {
    int left = 0;
    int right = leftLen;
    rightLen += leftLen;
    while (right < rightLen) {
      if (left == leftLen || arr[pos + left] > arr[pos + right]) {
        swap(arr, pos + dist, pos + right);
        dist++;
        right++;
      } else {
        swap(arr, pos + dist, pos + left);
        dist++;
        left++;
      }
    }
    if (dist != left) {
      multiSwap(arr, pos + dist, pos + left, leftLen - left);
    }
  }

  public static void mergeRight(int[] arr, int pos, int leftLen, int rightLen, int dist) {
    int mergedPos = leftLen + rightLen + dist - 1;
    int right = leftLen + rightLen - 1;
    int left = leftLen - 1;
    while (left >= 0) {
      if (right < leftLen || arr[pos + left] > arr[pos + right]) {
        swap(arr, pos + mergedPos, pos + left);
        mergedPos--;
        left--;
      } else {
        swap(arr, pos + mergedPos, pos + right);
        mergedPos--;
        right--;
      }
    }
    while (right != mergedPos && right >= leftLen) {
      swap(arr, pos + mergedPos, pos + right);
      mergedPos--;
      right--;
    }
  }

  private static final class Pair {
    final int length;
    final int fragment;

    Pair(int length, int fragment) {
      this.length = length;
      this.fragment = fragment;
    }
  }

  public static Pair smartMergeWithoutBuffer(
      int[] arr, int pos, int leftOverLen, int leftOverFrag, int regBlockLen) {
    if (regBlockLen == 0) {
      return new Pair(leftOverLen, leftOverFrag);
    }
    int len1 = leftOverLen;
    int len2 = regBlockLen;
    int typeFrag = 1 - leftOverFrag;
    if (len1 != 0 && (compareValues(arr[pos + len1 - 1], arr[pos + len1]) - typeFrag) >= 0) {
      while (len1 != 0) {
        int foundLen = binSearch(arr, pos + len1, len2, pos, typeFrag != 0);
        if (foundLen != 0) {
          rotate(arr, pos, len1, foundLen);
          pos += foundLen;
          len2 -= foundLen;
        }
        if (len2 == 0) {
          return new Pair(len1, leftOverFrag);
        }
        do {
          pos++;
          len1--;
        } while (len1 != 0 && (compareValues(arr[pos], arr[pos + len1]) - typeFrag) < 0);
      }
    }
    return new Pair(len2, typeFrag);
  }

  public static Pair smartMergeWithBuffer(
      int[] arr, int pos, int leftOverLen, int leftOverFrag, int blockLen) {
    int dist = -blockLen;
    int left = 0;
    int right = leftOverLen;
    int leftEnd = right;
    int rightEnd = right + blockLen;
    int typeFrag = 1 - leftOverFrag;
    while (left < leftEnd && right < rightEnd) {
      if ((compareValues(arr[pos + left], arr[pos + right]) - typeFrag) < 0) {
        swap(arr, pos + dist, pos + left);
        dist++;
        left++;
      } else {
        swap(arr, pos + dist, pos + right);
        dist++;
        right++;
      }
    }
    int length;
    int fragment = leftOverFrag;
    if (left < leftEnd) {
      length = leftEnd - left;
      while (left < leftEnd) {
        leftEnd--;
        rightEnd--;
        swap(arr, pos + leftEnd, pos + rightEnd);
      }
    } else {
      length = rightEnd - right;
      fragment = typeFrag;
    }
    return new Pair(length, fragment);
  }

  public static void mergeBuffersLeft(
      int[] arr,
      int keysPos,
      int midkey,
      int pos,
      int blockCount,
      int blockLen,
      boolean havebuf,
      int aBlockCount,
      int lastLen) {
    if (blockCount == 0) {
      int aBlocksLen = aBlockCount * blockLen;
      if (havebuf) {
        mergeLeft(arr, pos, aBlocksLen, lastLen, -blockLen);
      } else {
        mergeWithoutBuffer(arr, pos, aBlocksLen, lastLen);
      }
      return;
    }
    int leftOverLen = blockLen;
    int leftOverFrag = (arr[keysPos] < arr[midkey]) ? 0 : 1;
    int processIndex = blockLen;
    for (int keyIndex = 1; keyIndex < blockCount; keyIndex++) {
      int restToProcess = processIndex - leftOverLen;
      int nextFrag = (arr[keysPos + keyIndex] < arr[midkey]) ? 0 : 1;
      if (nextFrag == leftOverFrag) {
        if (havebuf) {
          multiSwap(arr, pos + restToProcess - blockLen, pos + restToProcess, leftOverLen);
        }
        restToProcess = processIndex;
        leftOverLen = blockLen;
      } else {
        Pair result =
            havebuf
                ? smartMergeWithBuffer(
                    arr, pos + restToProcess, leftOverLen, leftOverFrag, blockLen)
                : smartMergeWithoutBuffer(
                    arr, pos + restToProcess, leftOverLen, leftOverFrag, blockLen);
        leftOverLen = result.length;
        leftOverFrag = result.fragment;
      }
      processIndex += blockLen;
    }
    int restToProcess = processIndex - leftOverLen;
    if (lastLen != 0) {
      if (leftOverFrag != 0) {
        if (havebuf) {
          multiSwap(arr, pos + restToProcess - blockLen, pos + restToProcess, leftOverLen);
        }
        restToProcess = processIndex;
        leftOverLen = blockLen * aBlockCount;
        leftOverFrag = 0;
      } else {
        leftOverLen += blockLen * aBlockCount;
      }
      if (havebuf) {
        mergeLeft(arr, pos + restToProcess, leftOverLen, lastLen, -blockLen);
      } else {
        mergeWithoutBuffer(arr, pos + restToProcess, leftOverLen, lastLen);
      }
    } else {
      if (havebuf) {
        multiSwap(arr, pos + restToProcess, pos + restToProcess - blockLen, leftOverLen);
      }
    }
  }

  public static void buildBlocks(int[] arr, int pos, int len, int buildLen) {
    for (int dist = 1; dist < len; dist += 2) {
      int extraDist = (arr[pos + dist - 1] > arr[pos + dist]) ? 1 : 0;
      swap(arr, pos + dist - 3, pos + dist - 1 + extraDist);
      swap(arr, pos + dist - 2, pos + dist - extraDist);
    }
    if (len % 2 == 1) {
      swap(arr, pos + len - 1, pos + len - 3);
    }
    pos -= 2;
    int part = 2;
    while (part < buildLen) {
      int left = 0;
      int right = len - 2 * part;
      while (left <= right) {
        mergeLeft(arr, pos + left, part, part, -part);
        left += 2 * part;
      }
      int rest = len - left;
      if (rest > part) {
        mergeLeft(arr, pos + left, part, rest - part, -part);
      } else {
        rotate(arr, pos + left - part, part, rest);
      }
      pos -= part;
      part *= 2;
    }
    int restToBuild = len % (2 * buildLen);
    int leftOverPos = len - restToBuild;
    if (restToBuild <= buildLen) {
      rotate(arr, pos + leftOverPos, restToBuild, buildLen);
    } else {
      mergeRight(arr, pos + leftOverPos, buildLen, restToBuild - buildLen, buildLen);
    }
    while (leftOverPos > 0) {
      leftOverPos -= 2 * buildLen;
      mergeRight(arr, pos + leftOverPos, buildLen, buildLen, buildLen);
    }
  }

  public static void combineBlocks(
      int[] arr, int keyPos, int pos, int len, int buildLen, int regBlockLen, boolean havebuf) {
    int combineLen = len / (2 * buildLen);
    int leftOver = len % (2 * buildLen);
    if (leftOver <= buildLen) {
      len -= leftOver;
      leftOver = 0;
    }
    for (int i = 0; i <= combineLen; i++) {
      if (i == combineLen && leftOver == 0) {
        break;
      }
      int blockPos = pos + i * 2 * buildLen;
      int blockCount = (i == combineLen ? leftOver : 2 * buildLen) / regBlockLen;
      insertSort(arr, keyPos, blockCount + (i == combineLen ? 1 : 0));
      int midkey = buildLen / regBlockLen;
      for (int index = 1; index < blockCount; index++) {
        int leftIndex = index - 1;
        for (int rightIndex = index; rightIndex < blockCount; rightIndex++) {
          int a = arr[blockPos + leftIndex * regBlockLen];
          int b = arr[blockPos + rightIndex * regBlockLen];
          if (a > b || (a == b && arr[keyPos + leftIndex] > arr[keyPos + rightIndex])) {
            leftIndex = rightIndex;
          }
        }
        if (leftIndex != index - 1) {
          multiSwap(
              arr,
              blockPos + (index - 1) * regBlockLen,
              blockPos + leftIndex * regBlockLen,
              regBlockLen);
          swap(arr, keyPos + (index - 1), keyPos + leftIndex);
          if (midkey == index - 1 || midkey == leftIndex) {
            midkey ^= (index - 1) ^ leftIndex;
          }
        }
      }
      int aBlockCount = 0;
      int lastLen = (i == combineLen) ? (leftOver % regBlockLen) : 0;
      if (lastLen != 0) {
        while (aBlockCount < blockCount
            && arr[blockPos + blockCount * regBlockLen]
                < arr[blockPos + (blockCount - aBlockCount - 1) * regBlockLen]) {
          aBlockCount++;
        }
      }
      mergeBuffersLeft(
          arr,
          keyPos,
          keyPos + midkey,
          blockPos,
          blockCount - aBlockCount,
          regBlockLen,
          havebuf,
          aBlockCount,
          lastLen);
    }
    if (havebuf) {
      while (len > 0) {
        len--;
        swap(arr, pos + len, pos + len - regBlockLen);
      }
    }
  }

  public static void lazyStableSort(int[] arr, int pos, int len) {
    for (int dist = 1; dist < len; dist += 2) {
      if (arr[pos + dist - 1] > arr[pos + dist]) {
        swap(arr, pos + dist - 1, pos + dist);
      }
    }
    int part = 2;
    while (part < len) {
      int left = 0;
      int right = len - 2 * part;
      while (left <= right) {
        mergeWithoutBuffer(arr, pos + left, part, part);
        left += 2 * part;
      }
      int rest = len - left;
      if (rest > part) {
        mergeWithoutBuffer(arr, pos + left, part, rest - part);
      }
      part *= 2;
    }
  }

  public static void commonSort(int[] arr, int pos, int len) {
    if (len <= 16) {
      insertSort(arr, pos, len);
      return;
    }
    int blockLen = 1;
    while (blockLen * blockLen < len) {
      blockLen *= 2;
    }
    int numKeys = (len - 1) / blockLen + 1;
    int keysFound = findKeys(arr, pos, len, numKeys + blockLen);
    boolean bufferEnabled = true;
    if (keysFound < numKeys + blockLen) {
      if (keysFound < 4) {
        lazyStableSort(arr, pos, len);
        return;
      }
      numKeys = blockLen;
      while (numKeys > keysFound) {
        numKeys /= 2;
      }
      bufferEnabled = false;
      blockLen = 0;
    }
    int dist = blockLen + numKeys;
    int buildLen = bufferEnabled ? blockLen : numKeys;
    buildBlocks(arr, pos + dist, len - dist, buildLen);
    while (true) {
      buildLen *= 2;
      if (len - dist <= buildLen) {
        break;
      }
      int regBlockLen = blockLen;
      boolean buildBufEnabled = bufferEnabled;
      if (!bufferEnabled) {
        if (numKeys > 4 && (numKeys / 8) * numKeys >= buildLen) {
          regBlockLen = numKeys / 2;
          buildBufEnabled = true;
        } else {
          int calcKeys = 1;
          int i = buildLen * keysFound / 2;
          while (calcKeys < numKeys && i != 0) {
            calcKeys *= 2;
            i /= 8;
          }
          regBlockLen = (2 * buildLen) / calcKeys;
        }
      }
      combineBlocks(arr, pos, pos + dist, len - dist, buildLen, regBlockLen, buildBufEnabled);
    }
    insertSort(arr, pos, dist);
    mergeWithoutBuffer(arr, pos, dist, len - dist);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    commonSort(arr, 0, n);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
