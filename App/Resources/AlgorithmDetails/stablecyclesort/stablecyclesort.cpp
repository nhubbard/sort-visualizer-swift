#include <cstdio>
#include <utility>
#include <vector>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

void printList(int items[], int size) {
  printf("[");
  if (size > 0) {
    printf("%d", items[0]);
    for (int i = 1; i < size; i++) {
      printf(", %d", items[i]);
    }
  }
  printf("]");
}

int destination(int arr[], std::vector<bool> &flagged, int a, int b1, int b);
void stableCycleSort(int arr[], int n);

void sort(int arr[], int n) {
  stableCycleSort(arr, n);
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
    if (!flagged[d])
      e--;
    d++;
  }
  return d;
}

void stableCycleSort(int arr[], int n) {
  if (n <= 1)
    return;
  std::vector<bool> flagged(n, false);
  for (int i = 0; i < n - 1; i++) {
    if (flagged[i])
      continue;
    int j = i;
    do {
      int k = destination(arr, flagged, i, j, n);
      std::swap(arr[i], arr[k]);
      flagged[k] = true;
      j = k;
    } while (j != i);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
