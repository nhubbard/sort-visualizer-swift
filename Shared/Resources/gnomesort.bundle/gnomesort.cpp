#include <cstdio>
#include <utility>

int items[10] = {35, 95, 74, 71, 72, 30, 96, 53, 9, 0};

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

void gnomeSort(int arr[], int n) {
  int index = 0;
  while (index < n) {
    if (index == 0) {
      index++;
    }
    if (arr[index] >= arr[index - 1]) {
      index++;
    } else {
      std::swap(arr[index], arr[index - 1]);
      index--;
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(items) / sizeof(items[0]);
  gnomeSort(items, size);
  printList(items, size);
  return 0;
}