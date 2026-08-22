#include <cstdio>

int array[5] = {0, 39, 21, 62, 14};

void printList(int arr[], int n) {
  for (int i = 0; i < n; i++) {
    if (i == 0) {
      printf("[%d, ", arr[i]);
    } else if (i != n - 1) {
      printf("%d, ", arr[i]);
    } else {
      printf("%d]", arr[i]);
    }
  }
}

bool isValid(int arr[], int loops[], int n) {
  for (int i = 0; i < n - 1; i++) {
    int a = arr[loops[i]];
    int b = arr[loops[i + 1]];
    if (a < b || (a == b && loops[i] < loops[i + 1])) {
      continue;
    }
    return false;
  }
  return true;
}

void sort(int arr[], int n) {
  int loops[n];
  for (int i = 0; i < n; i++) {
    loops[i] = 0;
  }

  while (!isValid(arr, loops, n)) {
    for (int pos = 0; pos < n; pos++) {
      if (loops[pos] < n - 1) {
        loops[pos]++;
        break;
      } else {
        loops[pos] = 0;
      }
    }
  }

  int mapped[n];
  for (int i = 0; i < n; i++) {
    mapped[i] = arr[loops[i]];
  }
  for (int i = 0; i < n; i++) {
    arr[i] = mapped[i];
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
