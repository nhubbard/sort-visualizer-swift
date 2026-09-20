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

bool circle(int arr[], int left, int right);
bool circlePass(int arr[], int left, int right);

void sort(int arr[], int n) {
  if (n <= 1) {
    return;
  }
  while (circlePass(arr, 0, n - 1)) {
    // repeat until a full sweep makes no swaps
  }
}

bool circle(int arr[], int left, int right) {
  int a = left;
  int b = right;
  bool swapped = false;
  while (a < b) {
    if (arr[a] > arr[b]) {
      std::swap(arr[a], arr[b]);
      swapped = true;
    }
    a++;
    b--;
    if (a == b) {
      b++;
    }
  }
  return swapped;
}

bool circlePass(int arr[], int left, int right) {
  if (left >= right) {
    return false;
  }
  int mid = (left + right) / 2;
  bool l = circlePass(arr, left, mid);
  bool r = circlePass(arr, mid + 1, right);
  return circle(arr, left, right) || l || r;
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
