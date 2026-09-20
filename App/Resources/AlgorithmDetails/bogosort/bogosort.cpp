#include <cstdio>
#include <algorithm>
#include <iostream>
#include <vector>
using namespace std;


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
  bool ordered = true;
  for (int i = 1; i < n; ++i)
    if (a[i] < a[i - 1]) {
      ordered = false;
      break;
    }
  if (ordered)
    return;
  while (true) {
    int pivot = n - 2;
    while (pivot >= 0 && a[pivot] >= a[pivot + 1])
      --pivot;
    if (pivot < 0)
      break;
    int successor = n - 1;
    while (a[successor] <= a[pivot])
      --successor;
    swap(a[pivot], a[successor]);
    reverse(a.begin() + pivot + 1, a.end());
  }
  reverse(a.begin(), a.end());
}
int main() {
  vector<int> a = {0, 39, 21, 62, 91, 77, 14, 23};
  sort(a);
  printList(a);
}
