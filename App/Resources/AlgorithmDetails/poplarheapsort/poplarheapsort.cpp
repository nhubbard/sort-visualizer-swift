#include <cstdio>
#include <utility>
#include <vector>

int hyperfloor(int n) {
  int power = 1;
  while (power * 2 <= n) {
    power *= 2;
  }
  return power;
}

void uncheckedInsertionSort(std::vector<int> &array, int first, int last) {
  int cur = first + 1;
  while (cur != last) {
    if (array[cur] < array[cur - 1]) {
      int tmp = array[cur];
      int sift = cur;
      int sift1 = cur - 1;
      while (true) {
        array[sift] = array[sift1];
        sift--;
        if (sift == first)
          break;
        sift1--;
        if (tmp >= array[sift1])
          break;
      }
      array[sift] = tmp;
    }
    cur++;
  }
}

void insertionSort(std::vector<int> &array, int first, int last) {
  if (first == last)
    return;
  uncheckedInsertionSort(array, first, last);
}

void poplarSift(std::vector<int> &array, int firstIn, int sizeIn) {
  int size = sizeIn;
  if (size < 2)
    return;
  int root = firstIn + (size - 1);
  int childRoot1 = root - 1;
  int childRoot2 = firstIn + (size / 2 - 1);
  while (true) {
    int maxRoot = root;
    if (array[maxRoot] < array[childRoot1])
      maxRoot = childRoot1;
    if (array[maxRoot] < array[childRoot2])
      maxRoot = childRoot2;
    if (maxRoot == root)
      return;
    std::swap(array[root], array[maxRoot]);
    size /= 2;
    if (size < 2)
      return;
    root = maxRoot;
    childRoot1 = root - 1;
    childRoot2 = maxRoot - (size - size / 2);
  }
}

void popHeapWithSize(std::vector<int> &array, int first, int last, int sizeIn) {
  int size = sizeIn;
  int poplarSize = hyperfloor(size + 1) - 1;
  int lastRoot = last - 1;
  int bigger = lastRoot;
  int biggerSize = poplarSize;

  int it = first;
  while (true) {
    int root = it + poplarSize - 1;
    if (root == lastRoot)
      break;
    if (array[bigger] < array[root]) {
      bigger = root;
      biggerSize = poplarSize;
    }
    it = root + 1;
    size -= poplarSize;
    poplarSize = hyperfloor(size + 1) - 1;
  }

  if (bigger != lastRoot) {
    std::swap(array[bigger], array[lastRoot]);
    poplarSift(array, bigger - (biggerSize - 1), biggerSize);
  }
}

void makeHeap(std::vector<int> &array, int first, int last) {
  int size = last - first;
  if (size < 2)
    return;
  int smallPoplarSize = 15;
  if (size <= smallPoplarSize) {
    uncheckedInsertionSort(array, first, last);
    return;
  }

  int poplarLevel = 1;
  int it = first;
  int next = it + smallPoplarSize;
  while (true) {
    uncheckedInsertionSort(array, it, next);
    int poplarSize = smallPoplarSize;
    int i = (poplarLevel & -poplarLevel) >> 1;
    while (i != 0) {
      it -= poplarSize;
      poplarSize = 2 * poplarSize + 1;
      if (it + poplarSize > last)
        break;
      poplarSift(array, it, poplarSize);
      next++;
      i >>= 1;
    }
    if ((last - next) <= smallPoplarSize) {
      insertionSort(array, next, last);
      return;
    }
    it = next;
    next += smallPoplarSize;
    poplarLevel++;
  }
}

void sortHeap(std::vector<int> &array, int first, int lastIn) {
  int last = lastIn;
  int size = last - first;
  if (size < 2)
    return;
  do {
    popHeapWithSize(array, first, last, size);
    last--;
    size--;
  } while (size > 1);
}

void sort(std::vector<int> &array) {
  int n = static_cast<int>(array.size());
  if (n <= 1)
    return;
  makeHeap(array, 0, n);
  sortHeap(array, 0, n);
}

int main() {
  std::vector<int> array = {0,  39, 21, 62, 91, 77, 14, 23,
                            90, 69, 51, 81, 68, 83, 32, 56};
  sort(array);
  printf("[");
  for (size_t i = 0; i < array.size(); i++) {
    printf("%d", array[i]);
    if (i != array.size() - 1)
      printf(", ");
  }
  printf("]\n");
  return 0;
}
