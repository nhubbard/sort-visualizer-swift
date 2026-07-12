#include <cmath>
#include <iostream>
#include <vector>

int triangularRoot(int val) {
  return (static_cast<int>(std::sqrt(static_cast<double>(8 * val + 1))) - 1) / 2;
}

void siftDown(std::vector<int> &array, int root, int size) {
  while (true) {
    int row = triangularRoot(root);
    int left = root + row + 1;
    if (left >= size) break;
    int right = left + 1;
    int largest = root;
    if (array[largest] < array[left]) largest = left;
    if (right < size && array[largest] < array[right]) largest = right;
    if (largest == root) break;
    std::swap(array[root], array[largest]);
    root = largest;
  }
}

void heapify(std::vector<int> &array, int length) {
  for (int i = length - 1; i >= 0; i--) {
    siftDown(array, i, length);
  }
}

void sort(std::vector<int> &array) {
  int n = static_cast<int>(array.size());
  if (n <= 1) return;
  heapify(array, n);
  for (int i = 1; i < n - 1; i++) {
    std::swap(array[0], array[n - i]);
    siftDown(array, 0, n - i);
  }
  if (array[0] > array[1]) {
    std::swap(array[0], array[1]);
  }
}

int main() {
  std::vector<int> array = {0, 39, 21, 62, 91, 77, 14, 23,
                             90, 69, 51, 81, 68, 83, 32, 56};
  sort(array);
  std::cout << "[";
  for (size_t i = 0; i < array.size(); i++) {
    std::cout << array[i];
    if (i != array.size() - 1) std::cout << ", ";
  }
  std::cout << "]" << std::endl;
  return 0;
}
