#include <cstdio>
#include <vector>

static int idx;

void traverse(const std::vector<int> &arr, std::vector<int> &temp,
              std::vector<int> &lower, std::vector<int> &upper, int r) {
  if (lower[r] != 0) {
    traverse(arr, temp, lower, upper, lower[r]);
  }
  temp[idx++] = arr[r];
  if (upper[r] != 0) {
    traverse(arr, temp, lower, upper, upper[r]);
  }
}

void sort(std::vector<int> &arr) {
  int n = (int)arr.size();
  if (n <= 1) {
    return;
  }
  std::vector<int> lower(n, 0);
  std::vector<int> upper(n, 0);

  for (int i = 1; i < n; i++) {
    int c = 0;
    while (true) {
      std::vector<int> &next = (arr[i] < arr[c]) ? lower : upper;
      if (next[c] == 0) {
        next[c] = i;
        break;
      } else {
        c = next[c];
      }
    }
  }

  std::vector<int> temp(n);
  idx = 0;
  traverse(arr, temp, lower, upper, 0);
  arr = temp;
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
