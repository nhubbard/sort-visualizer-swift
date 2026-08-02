#include <cstdio>
#include <queue>
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
  std::vector<std::vector<int>> piles;
  std::vector<int> tops;

  for (int i = 0; i < n; i++) {
    int x = arr[i];
    // binary search: leftmost pile whose top is >= x
    int lo = 0;
    int hi = static_cast<int>(piles.size());
    while (lo < hi) {
      int mid = (lo + hi) / 2;
      if (tops[mid] >= x) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    if (lo == static_cast<int>(piles.size())) {
      piles.push_back({x});
      tops.push_back(x);
    } else {
      piles[lo].push_back(x);
      tops[lo] = x;
    }
  }

  using Entry = std::pair<int, int>; // (topValue, pileIndex)
  std::priority_queue<Entry, std::vector<Entry>, std::greater<Entry>> heap;
  for (int i = 0; i < static_cast<int>(piles.size()); i++) {
    heap.push({tops[i], i});
  }

  std::vector<int> result;
  result.reserve(n);
  while (!heap.empty()) {
    Entry entry = heap.top();
    heap.pop();
    int pileIndex = entry.second;
    int value = piles[pileIndex].back();
    piles[pileIndex].pop_back();
    result.push_back(value);
    if (!piles[pileIndex].empty()) {
      heap.push({piles[pileIndex].back(), pileIndex});
    }
  }

  for (int i = 0; i < n; i++) {
    arr[i] = result[i];
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}