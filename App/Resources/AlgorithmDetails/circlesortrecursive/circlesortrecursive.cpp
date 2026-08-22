#include <cstdio>
#include <utility>

int nextPowerOfTwo(int n) {
  int k = 1;
  while (k < n) {
    k <<= 1;
  }
  return k;
}

int circleSortRoutine(int arr[], int lo, int hi, int end) {
  if (lo == hi) {
    return 0;
  }
  int low = lo;
  int high = hi;
  int mid = (hi - lo) / 2;
  int swaps = 0;
  while (lo < hi) {
    // clang-tidy can't prove lo/hi stay within [0, end) across the recursive
    // calls below; by induction from the initial (0, paddedLength - 1) call, lo
    // only increases from >= 0 and hi only decreases while staying >= lo, so
    // this never actually goes out of bounds.
    if (hi < end &&
        arr[lo] > arr[hi]) { // NOLINT(clang-analyzer-security.ArrayBound)
      std::swap(arr[lo], arr[hi]);
      swaps++;
    }
    lo++;
    hi--;
  }
  swaps += circleSortRoutine(arr, low, low + mid, end);
  if (low + mid + 1 < end) {
    swaps += circleSortRoutine(arr, low + mid + 1, high, end);
  }
  return swaps;
}

void sort(int arr[], int n) {
  if (n == 0) {
    return;
  }
  int paddedLength = nextPowerOfTwo(n);
  int swaps;
  do {
    swaps = circleSortRoutine(arr, 0, paddedLength - 1, n);
  } while (swaps != 0);
}

void printList(int arr[], int n) {
  for (int i = 0; i < n; i++) {
    if (i == 0) {
      printf("[%d, ", arr[i]);
    } else if (i != n - 1) {
      printf("%d, ", arr[i]);
    } else {
      printf("%d]", arr[i]);
    }
  }
}

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
