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
int floorLog2(int n);
void simpleShatterSort(int arr[], int length, int num, int rate);

void sort(int arr[], int n) {
  if (n < 2) return;
  int rate = std::max(2, floorLog2(n) / 2);
  simpleShatterSort(arr, n, 4, rate);
}

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

int floorLog2(int n) {
  int log = 0;
  int m = n;
  while (m > 1) {
    m >>= 1;
    log++;
  }
  return log;
}

void simpleShatterSort(int arr[], int length, int num, int rate) {
  int i = num;
  while (i > 1) {
    shatterPartition(arr, 0, length, i);
    i = i / rate;
  }
  std::vector<int> offsets = shatterPartition(arr, 0, length, 1);
  for (size_t k = 0; k + 1 < offsets.size(); k++) {
    if (offsets[k + 1] - offsets[k] > 1) {
      insertionSort(arr, offsets[k], offsets[k + 1]);
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
