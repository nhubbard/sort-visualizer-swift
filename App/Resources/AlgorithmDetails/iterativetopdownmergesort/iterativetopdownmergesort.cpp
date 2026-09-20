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

void merge(int arr[], std::vector<int>& scratch, int low, int mid, int high);

void sort(int arr[], int n) {
  if (n < 2) return;
  std::vector<int> scratch(n);
  int subarrayCount = 1;
  while (subarrayCount < n) {
    subarrayCount *= 2;
  }

  while (subarrayCount > 1) {
    for (int i = 0; i < subarrayCount; i += 2) {
      int low = n * i / subarrayCount;
      int mid = n * (i + 1) / subarrayCount;
      int high = n * (i + 2) / subarrayCount;
      merge(arr, scratch, low, mid, high);
    }
    subarrayCount /= 2;
  }
}

void merge(int arr[], std::vector<int>& scratch, int low, int mid, int high) {
  int left = low, right = mid, out = low;
  while (left < mid && right < high) {
    scratch[out++] = arr[left] <= arr[right] ? arr[left++] : arr[right++];
  }
  while (left < mid) scratch[out++] = arr[left++];
  while (right < high) scratch[out++] = arr[right++];
  for (int i = low; i < high; i++) arr[i] = scratch[i];
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
