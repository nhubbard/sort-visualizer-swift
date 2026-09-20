#include <cstdio>
#include <utility>

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

void insertionSort(int arr[], int left, int right);
void dualPivot(int arr[], int left, int right, int divisor);

void sort(int arr[], int left, int right) {
  dualPivot(arr, left, right, 3);
}

void insertionSort(int arr[], int left, int right) {
  for (int i = left + 1; i <= right; i++) {
    int j = i;
    while (j > left && arr[j] < arr[j - 1]) {
      std::swap(arr[j], arr[j - 1]);
      j--;
    }
  }
}

void dualPivot(int arr[], int left, int right, int divisor) {
  int length = right - left;
  if (length < 4) {
    insertionSort(arr, left, right);
    return;
  }
  int third = length / divisor;
  int med1 = left + third, med2 = right - third;
  if (med1 <= left) med1 = left + 1;
  if (med2 >= right) med2 = right - 1;
  if (arr[med1] < arr[med2]) {
    std::swap(arr[med1], arr[left]);
    std::swap(arr[med2], arr[right]);
  } else {
    std::swap(arr[med1], arr[right]);
    std::swap(arr[med2], arr[left]);
  }
  int pivot1 = arr[left], pivot2 = arr[right];
  int less = left + 1, great = right - 1;
  for (int k = less; k <= great; k++) {
    if (arr[k] < pivot1) {
      std::swap(arr[k], arr[less++]);
    } else if (arr[k] > pivot2) {
      while (k < great && arr[great] > pivot2) great--;
      std::swap(arr[k], arr[great--]);
      if (arr[k] < pivot1) std::swap(arr[k], arr[less++]);
    }
  }
  if (great - less < 13) divisor++;
  std::swap(arr[less - 1], arr[left]);
  std::swap(arr[great + 1], arr[right]);
  dualPivot(arr, left, less - 2, divisor);
  if (pivot1 < pivot2) dualPivot(arr, less, great, divisor);
  dualPivot(arr, great + 2, right, divisor);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, 0, size - 1);
  printList(array, size);
  return 0;
}
