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

// [start, stop) is the half-open range being sorted. merge selects whether
// the two halves are recursively pre-sorted before the fixed diamond
// comparison pattern below merges them together.
void sort(int arr[], int start, int stop, bool merge) {
  if (stop - start == 2) {
    if (arr[start] > arr[stop - 1]) {
      std::swap(arr[start], arr[stop - 1]);
    }
  } else if (stop - start >= 3) {
    double div = (stop - start) / 4.0;
    int mid = (stop - start) / 2 + start;
    int quarter = (int)div + start;
    int threeQuarters = (int)(div * 3) + start;

    if (merge) {
      sort(arr, start, mid, true);
      sort(arr, mid, stop, true);
    }
    sort(arr, quarter, threeQuarters, false);
    sort(arr, start, mid, false);
    sort(arr, mid, stop, false);
    sort(arr, quarter, threeQuarters, false);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, 0, size, true);
  printList(array, size);
  return 0;
}
