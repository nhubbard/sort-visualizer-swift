#include <cstdio>
#include <vector>

void merge(std::vector<int> &arr, std::vector<int> &tmp, int length,
           int residue, int modulus);

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

void sort(std::vector<int> &arr) {
  std::vector<int> tmp(arr.size());
  merge(arr, tmp, (int)arr.size(), 0, 1);
}

void merge(std::vector<int> &arr, std::vector<int> &tmp, int length,
           int residue, int modulus) {
  if (residue + modulus >= length) {
    return;
  }
  int low = residue;
  int high = residue + modulus;
  int dmodulus = modulus << 1;

  merge(arr, tmp, length, low, dmodulus);
  merge(arr, tmp, length, high, dmodulus);

  int nxt = residue;
  while (low < length && high < length) {
    if (arr[low] > arr[high] || (arr[low] == arr[high] && low > high)) {
      tmp[nxt] = arr[high];
      high += dmodulus;
    } else {
      tmp[nxt] = arr[low];
      low += dmodulus;
    }
    nxt += modulus;
  }
  if (low >= length) {
    while (high < length) {
      tmp[nxt] = arr[high];
      nxt += modulus;
      high += dmodulus;
    }
  } else {
    while (low < length) {
      tmp[nxt] = arr[low];
      nxt += modulus;
      low += dmodulus;
    }
  }
  for (int i = residue; i < length; i += modulus) {
    arr[i] = tmp[i];
  }
}



int main() {
  std::vector<int> array = {0,  39, 21, 62, 91, 77, 14, 23,
                            90, 69, 51, 81, 68, 83, 32, 56};
  sort(array);
  printList(array);
  return 0;
}
