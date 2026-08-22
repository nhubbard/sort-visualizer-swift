#include <cstdio>
#include <utility>
#include <vector>

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

bool compositeLess(int arr[], std::vector<int> &key, int mid, int i) {
  if (arr[mid] < arr[i])
    return true;
  if (arr[mid] == arr[i])
    return key[mid] < key[i];
  return false;
}

int binarySearch(int arr[], std::vector<int> &key, int n, int i) {
  int start = 0;
  int end = n - 1;
  while (start < end) {
    int mid = (start + end) / 2;
    if (compositeLess(arr, key, mid, i)) {
      start = mid + 1;
    } else {
      end = mid;
    }
  }
  return start;
}

void sort(int arr[], int n) {
  std::vector<int> key(n);
  for (int i = 0; i < n; i++)
    key[i] = i;

  for (int i = 1; i < n; i++) {
    bool done = false;
    while (!done) {
      int pos = binarySearch(arr, key, n, i);
      if (pos == i) {
        done = true;
      } else if (i < pos - 1) {
        std::swap(arr[i], arr[pos - 1]);
        std::swap(key[i], key[pos - 1]);
      } else {
        std::swap(arr[i], arr[pos]);
        std::swap(key[i], key[pos]);
      }
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}