#include <cstdio>
#include <vector>

void sort(std::vector<int> &array) {
  int currentLen = (int)array.size();
  for (int i = 0; i < currentLen; i++) {
    int shortest = i;

    int j = i;
    while (j < currentLen) {
      bool isShortest = true;
      int k = j + 1;
      while (k < currentLen) {
        if (array[j] > array[k]) {
          isShortest = false;
          break;
        }
        k++;
      }
      if (isShortest) {
        shortest = j;
        break;
      }
      j++;
    }

    std::swap(array[i], array[shortest]);
  }
}

void printList(const std::vector<int> &arr) {
  printf("[");
  for (size_t i = 0; i < arr.size(); i++) {
    printf("%d%s", arr[i], i + 1 == arr.size() ? "" : ", ");
  }
  printf("]\n");
}

int main() {
  std::vector<int> array = {0, 39, 21, 62, 91, 77, 14, 23,
                             90, 69, 51, 81, 68, 83, 32, 56};
  sort(array);
  printList(array);
  return 0;
}
