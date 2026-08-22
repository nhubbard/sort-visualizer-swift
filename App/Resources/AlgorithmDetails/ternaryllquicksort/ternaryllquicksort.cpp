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

std::pair<int, int> partitionTernaryLL(int arr[], int lo, int hi) {
  int p = selectPivot(arr, lo, hi);
  std::swap(arr[p], arr[hi - 1]);
  int pivotIndex = hi - 1;

  int i = lo;
  int k = hi - 1;

  for (int j = lo; j < k; j++) {
    int cmp = compare3(arr, j, pivotIndex);
    if (cmp == 0) {
      k--;
      std::swap(arr[k], arr[j]);
      j--;
    } else if (cmp < 0) {
      std::swap(arr[i], arr[j]);
      i++;
    }
  }

  for (int s = 0; s < hi - k; s++) {
    std::swap(arr[i + s], arr[hi - 1 - s]);
  }

  return std::make_pair(i, i + (hi - k));
}

void quicksortTernaryLL(int arr[], int lo, int hi) {
  if (lo + 1 < hi) {
    std::pair<int, int> mid = partitionTernaryLL(arr, lo, hi);
    quicksortTernaryLL(arr, lo, mid.first);
    quicksortTernaryLL(arr, mid.second, hi);
  }
}

void sort(int arr[], int n) { quicksortTernaryLL(arr, 0, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
