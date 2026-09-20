#include <iostream>
#include <vector>
using namespace std;
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
  cout << "[";
  for (size_t i = 0; i < a.size(); ++i) {
    if (i)
      cout << ", ";
    cout << a[i];
  }
  cout << "]\n";
}
