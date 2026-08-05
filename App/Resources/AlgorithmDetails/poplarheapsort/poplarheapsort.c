#include <stdio.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

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

int hyperfloor(int n) {
  int power = 1;
  while (power * 2 <= n) {
    power *= 2;
  }
  return power;
}

void uncheckedInsertionSort(int arr[], int first, int last) {
  int cur = first + 1;
  while (cur != last) {
    if (arr[cur] < arr[cur - 1]) {
      int tmp = arr[cur];
      int sift = cur;
      int sift1 = cur - 1;
      while (1) {
        arr[sift] = arr[sift1];
        sift--;
        if (sift == first)
          break;
        sift1--;
        if (tmp >= arr[sift1])
          break;
      }
      arr[sift] = tmp;
    }
    cur++;
  }
}

void insertionSort(int arr[], int first, int last) {
  if (first == last)
    return;
  uncheckedInsertionSort(arr, first, last);
}

void poplarSift(int arr[], int firstIn, int sizeIn) {
  int size = sizeIn;
  if (size < 2)
    return;
  int root = firstIn + (size - 1);
  int childRoot1 = root - 1;
  int childRoot2 = firstIn + (size / 2 - 1);
  while (1) {
    int maxRoot = root;
    if (arr[maxRoot] < arr[childRoot1])
      maxRoot = childRoot1;
    if (arr[maxRoot] < arr[childRoot2])
      maxRoot = childRoot2;
    if (maxRoot == root)
      return;
    swap(&arr[root], &arr[maxRoot]);
    size /= 2;
    if (size < 2)
      return;
    root = maxRoot;
    childRoot1 = root - 1;
    childRoot2 = maxRoot - (size - size / 2);
  }
}

void popHeapWithSize(int arr[], int first, int last, int sizeIn) {
  int size = sizeIn;
  int poplarSize = hyperfloor(size + 1) - 1;
  int lastRoot = last - 1;
  int bigger = lastRoot;
  int biggerSize = poplarSize;

  int it = first;
  while (1) {
    int root = it + poplarSize - 1;
    if (root == lastRoot)
      break;
    if (arr[bigger] < arr[root]) {
      bigger = root;
      biggerSize = poplarSize;
    }
    it = root + 1;
    size -= poplarSize;
    poplarSize = hyperfloor(size + 1) - 1;
  }

  if (bigger != lastRoot) {
    swap(&arr[bigger], &arr[lastRoot]);
    poplarSift(arr, bigger - (biggerSize - 1), biggerSize);
  }
}

void makeHeap(int arr[], int first, int last) {
  int size = last - first;
  if (size < 2)
    return;
  int smallPoplarSize = 15;
  if (size <= smallPoplarSize) {
    uncheckedInsertionSort(arr, first, last);
    return;
  }

  int poplarLevel = 1;
  int it = first;
  int next = it + smallPoplarSize;
  while (1) {
    uncheckedInsertionSort(arr, it, next);
    int poplarSize = smallPoplarSize;
    int i = (poplarLevel & -poplarLevel) >> 1;
    while (i != 0) {
      it -= poplarSize;
      poplarSize = 2 * poplarSize + 1;
      if (it + poplarSize > last)
        break;
      poplarSift(arr, it, poplarSize);
      next++;
      i >>= 1;
    }
    if ((last - next) <= smallPoplarSize) {
      insertionSort(arr, next, last);
      return;
    }
    it = next;
    next += smallPoplarSize;
    poplarLevel++;
  }
}

void sortHeap(int arr[], int first, int lastIn) {
  int last = lastIn;
  int size = last - first;
  if (size < 2)
    return;
  do {
    popHeapWithSize(arr, first, last, size);
    last--;
    size--;
  } while (size > 1);
}

void sort(int arr[], int n) {
  if (n <= 1)
    return;
  makeHeap(arr, 0, n);
  sortHeap(arr, 0, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
