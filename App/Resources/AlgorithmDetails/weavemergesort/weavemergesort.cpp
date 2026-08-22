#include <cstdio>
#include <vector>

void multiSwap(std::vector<int> &arr, int pos, int to) {
  if (to - pos > 0) {
    for (int i = pos; i < to; i++) {
      std::swap(arr[i], arr[i + 1]);
    }
  } else {
    for (int i = pos; i > to; i--) {
      std::swap(arr[i], arr[i - 1]);
    }
  }
}

void weaveInsert(std::vector<int> &arr, int start, int end) {
  for (int j = start; j < end; j++) {
    int pos = j;
    while (pos > start && arr[pos] <= arr[pos - 1]) {
      std::swap(arr[pos], arr[pos - 1]);
      pos--;
    }
  }
}

void weaveMerge(std::vector<int> &arr, int min, int max, int mid) {
  int target = mid - min;
  for (int i = 1; i <= target; i++) {
    multiSwap(arr, mid + i, min + (i * 2) - 1);
  }
  weaveInsert(arr, min, max + 1);
}

void weaveMergeSort(std::vector<int> &arr, int min, int max) {
  if (max - min == 0) {
    return;
  } else if (max - min == 1) {
    if (arr[min] > arr[max]) {
      std::swap(arr[min], arr[max]);
    }
  } else {
    int mid = (min + max) / 2;
    weaveMergeSort(arr, min, mid);
    weaveMergeSort(arr, mid + 1, max);
    weaveMerge(arr, min, max, mid);
  }
}

void sort(std::vector<int> &arr) {
  if (arr.size() > 1) {
    weaveMergeSort(arr, 0, (int)arr.size() - 1);
  }
}

void printList(const std::vector<int> &arr) {
  printf("[");
  for (size_t i = 0; i < arr.size(); i++) {
    printf("%d%s", arr[i], i + 1 == arr.size() ? "" : ", ");
  }
  printf("]\n");
}

int main() {
  std::vector<int> array = {0,  39, 21, 62, 91, 77, 14, 23,
                            90, 69, 51, 81, 68, 83, 32, 56};
  sort(array);
  printList(array);
  return 0;
}
