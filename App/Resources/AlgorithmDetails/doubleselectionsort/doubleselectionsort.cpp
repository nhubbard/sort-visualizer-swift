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

void doubleSelectionSort(int arr[], int n) {
  if (n <= 1) {
    return;
  }

  int left = 0;
  int right = n - 1;
  int smallest = 0;
  int biggest = 0;

  while (left <= right) {
    for (int i = left; i <= right; i++) {
      if (arr[i] > arr[biggest]) {
        biggest = i;
      }
      if (arr[i] < arr[smallest]) {
        smallest = i;
      }
    }

    if (biggest == left) {
      biggest = smallest;
    }

    std::swap(arr[left], arr[smallest]);
    std::swap(arr[right], arr[biggest]);

    left++;
    right--;
    smallest = left;
    biggest = right;
  }
}

void sort(int arr[], int n) { doubleSelectionSort(arr, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
