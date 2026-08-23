#include <algorithm>
#include <cstdio>
#include <vector>

constexpr int kInsertionRun = 4;

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

void insertionSortRange(int arr[], int lo, int hi) {
  for (int i = lo + 1; i < hi; i++) {
    int key = arr[i];
    int j = i - 1;
    while (j >= lo && arr[j] > key) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[j + 1] = key;
  }
}

// Merges the two equal-length sorted runs source[lo, lo+runLength) and
// source[lo+runLength, lo+2*runLength) into dest, filling from both ends toward
// the middle at once instead of scanning front to back alone.
void parityMerge(int source[], int lo, int runLength, std::vector<int> &dest) {
  int left = lo;
  int right = lo + runLength;
  int leftEnd = lo + runLength - 1;
  int rightEnd = lo + 2 * runLength - 1;
  int front = lo;
  int back = lo + 2 * runLength - 1;

  for (int step = 0; step < runLength; step++) {
    if (source[left] <= source[right]) {
      dest[front] = source[left];
      left++;
    } else {
      dest[front] = source[right];
      right++;
    }
    front++;

    if (source[leftEnd] > source[rightEnd]) {
      dest[back] = source[leftEnd];
      leftEnd--;
    } else {
      dest[back] = source[rightEnd];
      rightEnd--;
    }
    back--;
  }
}

void mergeRange(int source[], int lo, int mid, int hi, std::vector<int> &dest) {
  int left = lo, right = mid, out = lo;
  while (left < mid && right < hi) {
    if (source[left] <= source[right]) {
      dest[out] = source[left];
      left++;
    } else {
      dest[out] = source[right];
      right++;
    }
    out++;
  }
  while (left < mid) {
    dest[out] = source[left];
    left++;
    out++;
  }
  while (right < hi) {
    dest[out] = source[right];
    right++;
    out++;
  }
}

void sort(int arr[], int n) {
  if (n < 2)
    return;
  std::vector<int> buffer(arr, arr + n);

  for (int lo = 0; lo < n; lo += kInsertionRun) {
    insertionSortRange(arr, lo, std::min(lo + kInsertionRun, n));
  }

  for (int runLength = kInsertionRun; runLength < n; runLength *= 2) {
    for (int lo = 0; lo < n; lo += runLength * 2) {
      int mid = std::min(lo + runLength, n);
      int hi = std::min(lo + runLength * 2, n);
      if (mid - lo == runLength && hi - mid == runLength) {
        parityMerge(arr, lo, runLength, buffer);
      } else if (mid < hi) {
        mergeRange(arr, lo, mid, hi, buffer);
      } else {
        for (int i = lo; i < mid; i++)
          buffer[i] = arr[i];
      }
    }
    for (int i = 0; i < n; i++)
      arr[i] = buffer[i];
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
