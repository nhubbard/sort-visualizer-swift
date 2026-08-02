#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void printList(int items[], int size) {
  for (int i = 0; i < size; i++) {
    if (i == 0) {
      printf("[%d, ", items[i]);
    } else if (i != size - 1) {
      printf("%d, ", items[i]);
    } else {
      printf("%d]", items[i]);
    }
  }
}

void multiSwap(int arr[], int a, int b, int count) {
  for (int i = 0; i < count; i++)
    std::swap(arr[a + i], arr[b + i]);
}

void rotate(int arr[], int pos, int lenA, int lenB) {
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

int binSearch(int arr[], int pos, int len, int keyPos, bool isLeft) {
  int left = 0, right = len;
  while (left < right) {
    int mid = left + (right - left) / 2;
    bool cond = isLeft ? (arr[pos + mid] < arr[keyPos])
                       : (arr[pos + mid] <= arr[keyPos]);
    if (cond)
      left = mid + 1;
    else
      right = mid;
  }
  return left;
}

void mergeWithoutBuffer(int arr[], int pos, int len1, int len2) {
  if (len1 == 0 || len2 == 0)
    return;
  if (len1 == 1) {
    int loc = binSearch(arr, pos + 1, len2, pos, true);
    rotate(arr, pos, 1, loc);
    return;
  }
  if (len2 == 1) {
    int loc = binSearch(arr, pos, len1, pos + len1, false);
    rotate(arr, pos + loc, len1 - loc, 1);
    return;
  }
  int mid1 = len1 / 2;
  int loc = binSearch(arr, pos + len1, len2, pos + mid1, true);
  rotate(arr, pos + mid1, len1 - mid1, loc);
  mergeWithoutBuffer(arr, pos, mid1, loc);
  mergeWithoutBuffer(arr, pos + mid1 + loc, len1 - mid1, len2 - loc);
}

void sort(int arr[], int n) {
  int dist = 1;
  while (dist < n) {
    if (arr[dist - 1] > arr[dist])
      std::swap(arr[dist - 1], arr[dist]);
    dist += 2;
  }
  int part = 2;
  while (part < n) {
    int left = 0;
    int right = n - 2 * part;
    while (left <= right) {
      mergeWithoutBuffer(arr, left, part, part);
      left += 2 * part;
    }
    int rest = n - left;
    if (rest > part)
      mergeWithoutBuffer(arr, left, part, rest - part);
    part *= 2;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
