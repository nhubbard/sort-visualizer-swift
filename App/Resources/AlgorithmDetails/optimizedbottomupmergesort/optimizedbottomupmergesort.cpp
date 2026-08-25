#include <algorithm>
#include <cstdio>
#include <vector>

constexpr int kBlockSize = 16;

int array[40] = {81, 14, 3,  94, 35, 31, 28, 17, 94, 13, 86, 94, 69, 11,
                 75, 54, 4,  3,  11, 27, 29, 64, 77, 3,  71, 25, 91, 83,
                 89, 69, 53, 28, 57, 75, 35, 0,  97, 20, 89, 54};

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

void binaryInsertionSort(int arr[], int lo, int hi) {
  for (int i = lo + 1; i < hi; i++) {
    int key = arr[i];
    int left = lo, right = i;
    while (left < right) {
      int mid = (left + right) / 2;
      if (arr[mid] <= key) {
        left = mid + 1;
      } else {
        right = mid;
      }
    }
    for (int j = i; j > left; j--) {
      arr[j] = arr[j - 1];
    }
    arr[left] = key;
  }
}

void merge(int src[], int dst[], int low, int mid, int high) {
  int i = low, j = mid, k = low;
  while (i < mid && j < high) {
    if (src[i] <= src[j]) {
      dst[k++] = src[i++];
    } else {
      dst[k++] = src[j++];
    }
  }
  while (i < mid) {
    dst[k++] = src[i++];
  }
  while (j < high) {
    dst[k++] = src[j++];
  }
}

void sort(int arr[], int n) {
  if (n < kBlockSize) {
    binaryInsertionSort(arr, 0, n);
    return;
  }

  // Pre-pass: sort fixed-size blocks with binary insertion sort so the merge
  // phase can start from already-sorted runs instead of single elements.
  for (int low = 0; low < n; low += kBlockSize) {
    binaryInsertionSort(arr, low, std::min(low + kBlockSize, n));
  }

  // Merge phase: ping-pong between arr and scratch, alternating direction
  // every pass, instead of always merging into scratch and copying the whole
  // buffer back.
  std::vector<int> scratch(n);
  int *src = arr;
  int *dst = scratch.data();
  int passes = 0;
  for (int width = kBlockSize; width < n; width *= 2) {
    for (int low = 0; low < n; low += 2 * width) {
      int mid = std::min(low + width, n);
      int high = std::min(low + 2 * width, n);
      if (mid < high) {
        merge(src, dst, low, mid, high);
      } else {
        for (int i = low; i < mid; i++) {
          dst[i] = src[i];
        }
      }
    }
    std::swap(src, dst);
    passes++;
  }

  // An even number of passes lands the sorted result back in arr on its own;
  // an odd number leaves it in scratch, needing this one explicit copy back.
  if (passes % 2 == 1) {
    for (int i = 0; i < n; i++) {
      arr[i] = src[i];
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
