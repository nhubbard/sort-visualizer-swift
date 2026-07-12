#include <iostream>
#include <vector>

int leftBinarySearch(std::vector<int> &array, int a, int b, int val) {
  int lo = a, hi = b;
  while (lo < hi) {
    int mid = lo + (hi - lo) / 2;
    if (val <= array[mid]) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

int rightBinarySearch(std::vector<int> &array, int a, int b, int val) {
  int lo = a, hi = b;
  while (lo < hi) {
    int mid = lo + (hi - lo) / 2;
    if (val < array[mid]) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

void insertToLeft(std::vector<int> &array, int a, int b, int temp) {
  while (a > b) {
    array[a] = array[a - 1];
    a--;
  }
  array[b] = temp;
}

void insertToRight(std::vector<int> &array, int a, int b, int temp) {
  while (a < b) {
    array[a] = array[a + 1];
    a++;
  }
  array[a] = temp;
}

void doubleInsertion(std::vector<int> &array, int a, int b) {
  if (b - a < 2) {
    return;
  }

  int j = a + (b - a - 2) / 2 + 1;
  int i = a + (b - a - 1) / 2;

  if (j > i && array[i] > array[j]) {
    std::swap(array[i], array[j]);
  }
  i--;
  j++;

  while (j < b) {
    if (array[i] > array[j]) {
      int l = array[j];
      int r = array[i];
      int m = rightBinarySearch(array, i + 1, j, l);
      insertToRight(array, i, m - 1, l);
      int dest = leftBinarySearch(array, m, j, r);
      insertToLeft(array, j, dest, r);
    } else {
      int l = array[i];
      int r = array[j];
      int m = leftBinarySearch(array, i + 1, j, l);
      insertToRight(array, i, m - 1, l);
      int dest = rightBinarySearch(array, m, j, r);
      insertToLeft(array, j, dest, r);
    }
    i--;
    j++;
  }
}

void sort(std::vector<int> &arr) {
  if (arr.size() > 1) {
    doubleInsertion(arr, 0, static_cast<int>(arr.size()));
  }
}

int main() {
  std::vector<int> array = {0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56};
  sort(array);

  std::cout << "[";
  for (size_t i = 0; i < array.size(); i++) {
    std::cout << array[i];
    if (i != array.size() - 1) {
      std::cout << ", ";
    }
  }
  std::cout << "]" << std::endl;
  return 0;
}
