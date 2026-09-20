#include <cstdio>
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

int stablePartition(int arr[], int start, int end);
void stableQuickSort(int arr[], int start, int end);

void sort(int arr[], int n) {
  stableQuickSort(arr, 0, n - 1);
}

int stablePartition(int arr[], int start, int end) {
  int pivotValue = arr[start];
  std::vector<int> leftList;
  std::vector<int> rightList;

  for (int i = start + 1; i <= end; i++) {
    if (arr[i] < pivotValue) {
      leftList.push_back(arr[i]);
    } else {
      rightList.push_back(arr[i]);
    }
  }

  int writeIndex = start;
  for (int v : leftList) {
    arr[writeIndex++] = v;
  }
  int pivotIndex = writeIndex;
  arr[writeIndex++] = pivotValue;
  for (int v : rightList) {
    arr[writeIndex++] = v;
  }
  return pivotIndex;
}

void stableQuickSort(int arr[], int start, int end) {
  if (start < end) {
    int p = stablePartition(arr, start, end);
    stableQuickSort(arr, start, p - 1);
    stableQuickSort(arr, p + 1, end);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
