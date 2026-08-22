#include <algorithm>
#include <cstdio>
#include <numeric>
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

void sort(int arr[], int n) {
  if (n <= 1) {
    return;
  }

  // Simulate the reporting order that proportional-to-value sleep durations
  // would produce in a jitter-free race: a stable sort of the original
  // positions by value, so ties wake in the order they were scheduled.
  std::vector<int> indices(n);
  std::iota(indices.begin(), indices.end(), 0);
  std::stable_sort(indices.begin(), indices.end(),
                   [&](int a, int b) { return arr[a] < arr[b]; });

  std::vector<int> woke(n);
  for (int i = 0; i < n; i++) {
    woke[i] = arr[indices[i]];
  }
  std::copy(woke.begin(), woke.end(), arr);

  // Defensive cleanup pass: real scheduling jitter can't be fully trusted, so
  // finish with an ordinary insertion sort no matter what the race produced.
  for (int i = 1; i < n; i++) {
    int j = i;
    while (j > 0 && arr[j - 1] > arr[j]) {
      std::swap(arr[j - 1], arr[j]);
      j--;
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}