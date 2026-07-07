#include <cstdio>
#include <utility>
#include <vector>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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
  printf("\n");
}

int minRunLength(int n) {
  int r = 0;
  while (n >= 64) {
    r |= n & 1;
    n >>= 1;
  }
  return n + r;
}

void cocktailShakerSort(int arr[], int start, int end) {
  int length = end - start;
  if (length <= 1) {
    return;
  }
  int i = 0;
  while (i < length / 2) {
    bool isSorted = true;
    int j = i;
    while (j < length - i - 1) {
      if (arr[start + j] > arr[start + j + 1]) {
        std::swap(arr[start + j], arr[start + j + 1]);
        isSorted = false;
      }
      j++;
    }
    j = length - i - 1;
    while (j > i) {
      if (arr[start + j - 1] > arr[start + j]) {
        std::swap(arr[start + j - 1], arr[start + j]);
        isSorted = false;
      }
      j--;
    }
    if (isSorted) {
      break;
    }
    i++;
  }
}

void merge(int arr[], int start, int mid, int end) {
  std::vector<int> left(arr + start, arr + mid);
  std::vector<int> right(arr + mid, arr + end);
  size_t i = 0, j = 0;
  int k = start;
  while (i < left.size() && j < right.size()) {
    if (left[i] <= right[j]) {
      arr[k] = left[i];
      i++;
    } else {
      arr[k] = right[j];
      j++;
    }
    k++;
  }
  while (i < left.size()) {
    arr[k] = left[i];
    i++;
    k++;
  }
  while (j < right.size()) {
    arr[k] = right[j];
    j++;
    k++;
  }
}

void cocktailMergeSort(int arr[], int n) {
  if (n <= 1) {
    return;
  }
  int minRun = minRunLength(n);
  if (n == minRun) {
    cocktailShakerSort(arr, 0, n);
    return;
  }
  int i = 0;
  while (i <= n - minRun) {
    cocktailShakerSort(arr, i, i + minRun);
    i += minRun;
  }
  if (i < n) {
    cocktailShakerSort(arr, i, n);
  }
  int width = minRun;
  while (width < n) {
    i = 0;
    while (i < n) {
      int mid = std::min(i + width, n);
      int end = std::min(i + 2 * width, n);
      if (mid < end) {
        merge(arr, i, mid, end);
      }
      i += 2 * width;
    }
    width *= 2;
  }
}

void sort(int arr[], int n) {
  cocktailMergeSort(arr, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
