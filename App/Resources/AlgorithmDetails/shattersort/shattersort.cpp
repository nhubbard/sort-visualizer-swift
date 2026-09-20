#include <algorithm>
#include <cstdio>
#include <utility>
#include <vector>

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

void insertionSort(int arr[], int start, int end);
std::vector<int> shatterPartition(int arr[], int start, int length, int num);
void shatterSort(int arr[], int length, int num);

void sort(int arr[], int n) {
  if (n < 2) return; shatterSort(arr, n, 4); }

void insertionSort(int arr[], int start, int end) {
  for (int i = start + 1; i < end; i++) {
    int pos = i;
    while (pos > start && arr[pos - 1] > arr[pos]) {
      std::swap(arr[pos - 1], arr[pos]);
      pos--;
    }
  }
}

std::vector<int> shatterPartition(int arr[], int start, int length, int num) {
  int minV = arr[start];
  int maxV = arr[start];
  for (int i = 1; i < length; i++) {
    minV = std::min(minV, arr[start + i]);
    maxV = std::max(maxV, arr[start + i]);
  }
  int valueRange = maxV - minV + 1;
  int shatters = (length + num - 1) / num;

  std::vector<std::vector<int>> buckets(shatters);
  for (int i = 0; i < length; i++) {
    int v = arr[start + i];
    int idx = (v - minV) * shatters / valueRange;
    if (idx > shatters - 1)
      idx = shatters - 1;
    buckets[idx].push_back(v);
  }

  std::vector<int> offsets(shatters + 1, 0);
  for (int i = 0; i < shatters; i++) {
    offsets[i + 1] = offsets[i] + (int)buckets[i].size();
  }

  int pos = start;
  for (auto &bucket : buckets) {
    for (int v : bucket) {
      arr[pos++] = v;
    }
  }
  return offsets;
}

void shatterSort(int arr[], int length, int num) {
  std::vector<int> offsets = shatterPartition(arr, 0, length, num);
  for (size_t i = 0; i + 1 < offsets.size(); i++) {
    if (offsets[i + 1] - offsets[i] > 1) {
      insertionSort(arr, offsets[i], offsets[i + 1]);
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
