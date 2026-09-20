#include <cstdio>
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
  bool swapped = true;
  while (swapped) {
    swapped = false;
    for (int i = 0; i + 1 < n; i++)
      if (a[i] > a[i + 1]) {
        int held = a[i];
        a[i] = a[i + 1];
        a[i + 1] = held;
        swapped = true;
      }
  }
}
int main() {
  vector<int> a = {0, 39, 21, 62, 91, 77, 14, 23};
  sort(a);
  printList(a);
}
