import java.util.Arrays;

public class unstablegrailsort {
  public static void swap(int[] arr, int a, int b) {
    int t = arr[a];
    arr[a] = arr[b];
    arr[b] = t;
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

  public static void mergeWithoutBuffer(int[] arr, int pos, int len1, int len2) {
    if (len1 == 0 || len2 == 0) {
      return;
    }
    if (len1 + len2 == 2) {
      if (arr[pos] > arr[pos + 1]) {
        swap(arr, pos, pos + 1);
      }
      return;
    }
    int mid1;
    int mid2;
    if (len1 > len2) {
      mid1 = len1 / 2;
      mid2 = binSearch(arr, pos + len1, len2, pos + mid1, true);
    } else {
      mid2 = len2 / 2;
      mid1 = binSearch(arr, pos, len1, pos + len1 + mid2, false);
    }
    rotate(arr, pos + mid1, len1 - mid1, mid2);
    mergeWithoutBuffer(arr, pos, mid1, mid2);
    mergeWithoutBuffer(arr, pos + mid1 + mid2, len1 - mid1, len2 - mid2);
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

  public static int smartMergeWithBuffer(int[] arr, int pos, int leftOverLen, int blockLen) {
    int dist = -blockLen;
    int left = 0;
    int right = leftOverLen;
    int leftEnd = right;
    int rightEnd = right + blockLen;
    int length;
    while (left < leftEnd && right < rightEnd) {
      if (arr[pos + left] <= arr[pos + right]) {
        swap(arr, pos + dist, pos + left);
        dist++;
        left++;
      } else {
        swap(arr, pos + dist, pos + right);
        dist++;
        right++;
      }
    }
    if (left < leftEnd) {
      length = leftEnd - left;
      while (left < leftEnd) {
        leftEnd--;
        rightEnd--;
        swap(arr, pos + leftEnd, pos + rightEnd);
      }
    } else {
      length = rightEnd - right;
    }
    return length;
  }

  public static void mergeBuffersLeft(
      int[] arr, int pos, int blockCount, int blockLen, int aBlockCount, int lastLen) {
    if (blockCount == 0) {
      mergeLeft(arr, pos, aBlockCount * blockLen, lastLen, -blockLen);
      return;
    }
    int leftOverLen = blockLen;
    int processIndex = blockLen;
    for (int keyIndex = 1; keyIndex < blockCount; keyIndex++) {
      int restToProcess = processIndex - leftOverLen;
      leftOverLen = smartMergeWithBuffer(arr, pos + restToProcess, leftOverLen, blockLen);
      processIndex += blockLen;
    }
    int restToProcess = processIndex - leftOverLen;
    if (lastLen != 0) {
      leftOverLen += blockLen * aBlockCount;
      mergeLeft(arr, pos + restToProcess, leftOverLen, lastLen, -blockLen);
    } else {
      multiSwap(arr, pos + restToProcess, pos + restToProcess - blockLen, leftOverLen);
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

  public static void combineBlocks(int[] arr, int pos, int len, int buildLen, int regBlockLen) {
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
      for (int index = 1; index < blockCount; index++) {
        int leftIndex = index - 1;
        for (int rightIndex = index; rightIndex < blockCount; rightIndex++) {
          int a = arr[blockPos + leftIndex * regBlockLen];
          int b = arr[blockPos + rightIndex * regBlockLen];
          int cmp = Integer.compare(a, b);
          if (cmp > 0
              || (cmp == 0
                  && arr[blockPos + (leftIndex + 1) * regBlockLen - 1]
                      > arr[blockPos + (rightIndex + 1) * regBlockLen - 1])) {
            leftIndex = rightIndex;
          }
        }
        if (leftIndex != index - 1) {
          multiSwap(
              arr,
              blockPos + (index - 1) * regBlockLen,
              blockPos + leftIndex * regBlockLen,
              regBlockLen);
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
      mergeBuffersLeft(arr, blockPos, blockCount - aBlockCount, regBlockLen, aBlockCount, lastLen);
    }
    while (len > 0) {
      len--;
      swap(arr, pos + len, pos + len - regBlockLen);
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
    int buildLen = blockLen;
    buildBlocks(arr, pos + blockLen, len - blockLen, buildLen);
    while (true) {
      buildLen *= 2;
      if (len - blockLen <= buildLen) {
        break;
      }
      combineBlocks(arr, pos + blockLen, len - blockLen, buildLen, blockLen);
    }
    insertSort(arr, pos, blockLen);
    mergeWithoutBuffer(arr, pos, blockLen, len - blockLen);
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
