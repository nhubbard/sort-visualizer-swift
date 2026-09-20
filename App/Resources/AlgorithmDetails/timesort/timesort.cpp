#include <cstdio>
#include <algorithm>
#include <iostream>
#include <vector>
using namespace std;
static void mergeSort(vector<int> &scratch, vector<int> &buffer, int lo,
                      int hi);



void printList(const std::vector<int> &items) {
  printf("[");
  if (!items.empty()) {
    printf("%d", items[0]);
    for (size_t i = 1; i < items.size(); i++) {
      printf(", %d", items[i]);
    }
  }
  printf("]\n");
}

void sort(vector<int> &a) {
  int n = (int)a.size();
  if (n < 2)
    return;
  vector<int> scratch = a, buffer = scratch;
  mergeSort(scratch, buffer, 0, n);
  copy(scratch.begin(), scratch.end(), a.begin());
  for (int i = 1; i < n; i++)
    for (int j = i; j > 0 && a[j - 1] > a[j]; j--)
      swap(a[j - 1], a[j]);
}

static void mergeSort(vector<int> &scratch, vector<int> &buffer, int lo,
                      int hi) {
  if (hi - lo < 2)
    return;
  int mid = lo + (hi - lo) / 2;
  mergeSort(scratch, buffer, lo, mid);
  mergeSort(scratch, buffer, mid, hi);
  int left = lo, right = mid, dest = lo;
  while (left < mid && right < hi) {
    if (scratch[left] <= scratch[right])
      buffer[dest++] = scratch[left++];
    else
      buffer[dest++] = scratch[right++];
  }
  while (left < mid)
    buffer[dest++] = scratch[left++];
  while (right < hi)
    buffer[dest++] = scratch[right++];
  copy(buffer.begin() + lo, buffer.begin() + hi, scratch.begin() + lo);
}

int main() {
  vector<int> a = {0,  39, 21, 62, 91, 77, 14, 23,
                   90, 69, 51, 81, 68, 83, 32, 56};
  sort(a);
  printList(a);
}
