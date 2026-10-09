#include <cstdio>
#include <utility>
#include <vector>

int array[24] = {0,  39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81,
                 68, 83, 32, 56, 10, 2,  95, 46, 21, 74, 6,  38};

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

void mergeSort(int arr[], std::vector<int> &scratch, int start, int end) {
  if (end - start < 2)
    return;
  int middle = (start + end) / 2;
  mergeSort(arr, scratch, start, middle);
  mergeSort(arr, scratch, middle, end);
  int left = start, right = middle, dest = start;
  while (left < middle && right < end) {
    scratch[dest++] = arr[left] <= arr[right] ? arr[left++] : arr[right++];
  }
  while (left < middle)
    scratch[dest++] = arr[left++];
  while (right < end)
    scratch[dest++] = arr[right++];
  for (int i = start; i < end; i++)
    arr[i] = scratch[i];
}

int medianOfThree(int x, int y, int z) {
  if (x > y)
    std::swap(x, y);
  if (y > z)
    std::swap(y, z);
  if (x > y)
    std::swap(x, y);
  return y;
}

void sort(int arr[], int n) {
  std::vector<int> scratch(n);
  int start = 0, end = n;
  while (end - start > 16) {
    int pivot =
        medianOfThree(arr[start], arr[(start + end - 1) / 2], arr[end - 1]);
    int left = start, right = end - 1;
    while (left <= right) {
      while (left <= right && arr[left] < pivot)
        left++;
      while (left <= right && arr[right] > pivot)
        right--;
      if (left <= right)
        std::swap(arr[left++], arr[right--]);
    }
    if (left == start || left == end) {
      mergeSort(arr, scratch, start, end);
      return;
    }
    if (left - start <= end - left) {
      mergeSort(arr, scratch, start, left);
      start = left;
    } else {
      mergeSort(arr, scratch, left, end);
      end = left;
    }
  }
  for (int i = start + 1; i < end; i++) {
    int value = arr[i], j = i;
    while (j > start && arr[j - 1] > value) {
      arr[j] = arr[j - 1];
      j--;
    }
    arr[j] = value;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
