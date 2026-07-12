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
}

int destination(int arr[], std::vector<bool> &flagged, int a, int b1, int b) {
  int heldValue = arr[a];
  int d = a;
  int e = 0;
  for (int i = a + 1; i < b; i++) {
    if (arr[i] < heldValue) {
      d++;
    } else if (i < b1 && !flagged[i] && arr[i] == heldValue) {
      e++;
    }
  }
  while (flagged[d] || e > 0) {
    if (!flagged[d]) e--;
    d++;
  }
  return d;
}

void stableCycleSort(int arr[], int n) {
  if (n <= 1) return;
  std::vector<bool> flagged(n, false);
  for (int i = 0; i < n - 1; i++) {
    if (flagged[i]) continue;
    int j = i;
    do {
      int k = destination(arr, flagged, i, j, n);
      std::swap(arr[i], arr[k]);
      flagged[k] = true;
      j = k;
    } while (j != i);
  }
}

void sort(int arr[], int n) {
  stableCycleSort(arr, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
