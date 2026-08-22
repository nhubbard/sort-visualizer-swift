#include <algorithm>
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

int compare3(int arr[], int a, int b) {
  if (arr[a] == arr[b])
    return 0;
  return arr[a] > arr[b] ? 1 : -1;
}

int selectPivot(int arr[], int lo, int hi) {
  int mid = (lo + hi) / 2;
  int cLoMid = compare3(arr, lo, mid);
  if (cLoMid == 0)
    return lo;
  int cLoHi = compare3(arr, lo, hi - 1);
  int cMidHi = compare3(arr, mid, hi - 1);
  if (cLoHi == 0 || cMidHi == 0)
    return hi - 1;

  if (cLoMid < 0) {
    return cMidHi < 0 ? mid : (cLoHi < 0 ? hi - 1 : lo);
  } else {
    return cMidHi > 0 ? mid : (cLoHi < 0 ? lo : hi - 1);
  }
}

void quicksortTernaryLR(int arr[], int lo, int hi) {
  if (hi <= lo)
    return;

  int piv = selectPivot(arr, lo, hi + 1);
  std::swap(arr[piv], arr[hi]);
  int pivotIndex = hi;

  int i = lo, j = hi - 1;
  int p = lo, q = hi - 1;

  for (;;) {
    int cmp;
    while (i <= j && (cmp = compare3(arr, i, pivotIndex)) <= 0) {
      if (cmp == 0) {
        std::swap(arr[i], arr[p]);
        p++;
      }
      i++;
    }
    while (i <= j && (cmp = compare3(arr, j, pivotIndex)) >= 0) {
      if (cmp == 0) {
        std::swap(arr[j], arr[q]);
        q--;
      }
      j--;
    }
    if (i > j)
      break;
    std::swap(arr[i], arr[j]);
    i++;
    j--;
  }

  std::swap(arr[i], arr[hi]);

  int numLess = i - p;
  int numGreater = q - j;

  j = i - 1;
  i = i + 1;

  int pe = lo + std::min(p - lo, numLess);
  for (int k = lo; k < pe; k++, j--) {
    std::swap(arr[k], arr[j]);
  }

  int qe = hi - 1 - std::min(hi - 1 - q, numGreater - 1);
  for (int k = hi - 1; k > qe; k--, i++) {
    std::swap(arr[i], arr[k]);
  }

  quicksortTernaryLR(arr, lo, lo + numLess - 1);
  quicksortTernaryLR(arr, hi - numGreater + 1, hi);
}

void sort(int arr[], int n) { quicksortTernaryLR(arr, 0, n - 1); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
