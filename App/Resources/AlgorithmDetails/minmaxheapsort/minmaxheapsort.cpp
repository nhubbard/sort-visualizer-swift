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

int bitLength(int value) {
  int length = 0;
  while (value > 0) {
    value >>= 1;
    length++;
  }
  return length;
}

bool isMinLevel(int index) { return bitLength(index + 1) % 2 == 1; }

bool betterThan(int a, int b, bool minLevel) {
  return minLevel ? (a < b) : (a > b);
}

void downheap(int arr[], int start, int size) {
  int i = start;
  while (true) {
    bool minLevel = isMinLevel(i);
    int left = 2 * i + 1;
    int right = 2 * i + 2;
    if (left >= size)
      return;
    int winner = left;
    if (right < size && betterThan(arr[right], arr[winner], minLevel))
      winner = right;
    int base = 4 * i + 3;
    for (int offset = 0; offset < 4; offset++) {
      int gc = base + offset;
      if (gc < size && betterThan(arr[gc], arr[winner], minLevel))
        winner = gc;
    }
    bool isGrandchild = winner >= base;
    bool extreme = betterThan(arr[winner], arr[i], minLevel);
    if (!isGrandchild) {
      if (extreme)
        std::swap(arr[i], arr[winner]);
      return;
    }
    if (extreme) {
      std::swap(arr[i], arr[winner]);
    } else {
      return;
    }
    int parent = (winner - 1) / 2;
    if (minLevel) {
      if (arr[winner] > arr[parent])
        std::swap(arr[parent], arr[winner]);
    } else {
      if (arr[winner] < arr[parent])
        std::swap(arr[parent], arr[winner]);
    }
    i = winner;
  }
}

void heapify(int arr[], int length) {
  for (int i = (length - 1) / 2; i >= 0; i--) {
    downheap(arr, i, length);
  }
}

int storeMax(int arr[], int heapSize) {
  if (heapSize <= 1)
    return heapSize;
  int imax = 1;
  if (heapSize > 2 && arr[2] > arr[1])
    imax = 2;
  int last = heapSize - 1;
  std::swap(arr[imax], arr[last]);
  int newSize = last;
  if (imax < newSize)
    downheap(arr, imax, newSize);
  return newSize;
}

void sort(int arr[], int n) {
  if (n <= 1)
    return;
  heapify(arr, n);
  int heapSize = n;
  for (int i = 0; i < n - 1; i++) {
    heapSize = storeMax(arr, heapSize);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
