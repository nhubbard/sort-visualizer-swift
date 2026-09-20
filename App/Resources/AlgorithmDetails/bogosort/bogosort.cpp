#include <algorithm>
#include <iostream>
#include <vector>
using namespace std;
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
  cout << "[";
  for (size_t i = 0; i < a.size(); ++i) {
    if (i)
      cout << ", ";
    cout << a[i];
  }
  cout << "]\n";
}
