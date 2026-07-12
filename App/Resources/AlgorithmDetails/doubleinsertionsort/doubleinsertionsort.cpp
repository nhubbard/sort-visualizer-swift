#include <cstdio>
#include <utility>

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

void doubleInsertionSort(int arr[], int start, int end) {
  int left = start + (end - start) / 2 - 1;
  int right = left + 1;
  if (arr[left] > arr[right]) {
    std::swap(arr[left], arr[right]);
  }
  left--;
  right++;

  while (left >= start && right < end) {
    if (arr[left] > arr[right]) {
      int leftItem = arr[right];
      int rightItem = arr[left];

      int pos = left + 1;
      while (pos <= right && arr[pos] <= leftItem) {
        arr[pos - 1] = arr[pos];
        pos++;
      }
      arr[pos - 1] = leftItem;

      pos = right - 1;
      while (pos >= left && arr[pos] >= rightItem) {
        arr[pos + 1] = arr[pos];
        pos--;
      }
      arr[pos + 1] = rightItem;
    } else {
      int leftItem = arr[left];
      int rightItem = arr[right];

      int pos = left + 1;
      while (arr[pos] < leftItem) {
        arr[pos - 1] = arr[pos];
        pos++;
      }
      arr[pos - 1] = leftItem;

      pos = right - 1;
      while (arr[pos] > rightItem) {
        arr[pos + 1] = arr[pos];
        pos--;
      }
      arr[pos + 1] = rightItem;
    }

    left--;
    right++;
  }

  if (right < end) {
    int pos = right - 1;
    int current = arr[right];
    while (pos >= start && arr[pos] > current) {
      arr[pos + 1] = arr[pos];
      pos--;
    }
    arr[pos + 1] = current;
  }
}

void sort(int arr[], int n) {
  if (n > 1) {
    doubleInsertionSort(arr, 0, n);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
