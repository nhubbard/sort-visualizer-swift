#include <algorithm>
#include <cstdio>

int array[24] = {34, 7,  23, 90, 12, 56, 3,  45, 78, 21, 66, 9,
                 50, 15, 88, 40, 61, 5,  33, 72, 18, 95, 27, 60};

// Tags a value with its original index so a pending element can find its way
// back to the right chain partner even after the chain has been recursively
// reordered.
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

void blockSwap(int arr[], int a, int b, int size);
void blockInsert(int arr[], int a, int b, int size);
void blockReversal(int arr[], int a, int b, int size);
int blockSearch(int arr[], int a, int b, int size, int value);
void orderBlocks(int arr[], int a, int b, int size);

void sort(int arr[], int length) {
  if (length < 2) return;
  int k = 1;
  while (2 * k <= length) {
    for (int i = 2 * k - 1; i < length; i += 2 * k)
      if (arr[i - k] > arr[i]) blockSwap(arr, i - k, i, k);
    k *= 2;
  }
  while (k > 0) {
    int a = k - 1, i = a + 2 * k, g = 2, p = 4;
    while (i + 2 * k * g - k <= length) {
      orderBlocks(arr, i, i + 2 * k * g - k, k);
      int b = a + k * (p - 1);
      i += k * g - k;
      for (int j = i; j < i + k * g; j += k)
        blockInsert(arr, j, blockSearch(arr, a, b, k, arr[j]), k);
      i += k * g + k;
      g = p - g; p *= 2;
    }
    while (i < length) {
      blockInsert(arr, i, blockSearch(arr, a, i, k, arr[i]), k);
      i += 2 * k;
    }
    k /= 2;
  }
}

void blockSwap(int arr[], int a, int b, int size) {
  for (int offset = 0; offset < size; offset++) {
    int x = a - size + 1 + offset, y = b - size + 1 + offset;
    std::swap(arr[x], arr[y]);
  }
}

void blockInsert(int arr[], int a, int b, int size) {
  while (a - size >= b) { blockSwap(arr, a - size, a, size); a -= size; }
}

void blockReversal(int arr[], int a, int b, int size) {
  b -= size;
  while (b > a) { blockSwap(arr, a, b, size); a += size; b -= size; }
}

int blockSearch(int arr[], int a, int b, int size, int value) {
  while (a < b) {
    int mid = a + (((b - a) / size) / 2) * size;
    if (value < arr[mid]) b = mid;
    else a = mid + size;
  }
  return a;
}

void orderBlocks(int arr[], int a, int b, int size) {
  int i = a, j = i + size;
  while (j < b) { blockInsert(arr, j, i, size); i += size; j += 2 * size; }
  int mid = a + (((b - a) / size) / 2) * size;
  blockReversal(arr, mid, b, size);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
