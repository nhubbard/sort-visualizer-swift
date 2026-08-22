#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

void oddEvenMergeCompare(int arr[], int i, int j) {
  if (arr[i] > arr[j]) {
    std::swap(arr[i], arr[j]);
  }
}

// lo is the starting position, m2 is the halfway point, n is the length of
// the piece being merged, and r is the distance of the elements compared.
void oddEvenMerge(int arr[], int lo, int m2, int n, int r) {
  int m = r * 2;
  if (m < n) {
    if ((n / r) % 2 != 0) {
      oddEvenMerge(arr, lo, (m2 + 1) / 2, n + r, m); // even subsequence
      oddEvenMerge(arr, lo + r, m2 / 2, n - r, m);   // odd subsequence
    } else {
      oddEvenMerge(arr, lo, (m2 + 1) / 2, n, m); // even subsequence
      oddEvenMerge(arr, lo + r, m2 / 2, n, m);   // odd subsequence
    }

    if (m2 % 2 != 0) {
      for (int i = lo; i + r < lo + n; i += m) {
        oddEvenMergeCompare(arr, i, i + r);
      }
    } else {
      for (int i = lo + r; i + r < lo + n; i += m) {
        oddEvenMergeCompare(arr, i, i + r);
      }
    }
  } else {
    if (n > r) {
      oddEvenMergeCompare(arr, lo, lo + r);
    }
  }
}

void oddEvenMergeSort(int arr[], int lo, int n) {
  if (n > 1) {
    int m = n / 2;
    oddEvenMergeSort(arr, lo, m);
    oddEvenMergeSort(arr, lo + m, n - m);
    oddEvenMerge(arr, lo, m, n, 1);
  }
}

void sort(int arr[], int n) { oddEvenMergeSort(arr, 0, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
