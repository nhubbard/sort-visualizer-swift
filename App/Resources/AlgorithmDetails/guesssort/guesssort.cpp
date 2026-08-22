#include <cstdio>

int array[4] = {0, 39, 21, 14};

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
  int total = 0;
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      if (loops[i] == loops[j]) {
        total++;
      }
    }
  }
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      if ((i < j && arr[loops[i]] > arr[loops[j]]) ||
          (i > j && arr[loops[i]] < arr[loops[j]])) {
        total++;
      }
    }
  }
  return total == n;
}

void sort(int arr[], int n) {
  int loops[n];
  int indexes[n];
  for (int i = 0; i < n; i++) {
    loops[i] = 0;
    indexes[i] = 0;
  }

  while (true) {
    if (isValid(arr, loops, n)) {
      for (int i = 0; i < n; i++) {
        indexes[i] = loops[i];
      }
    }
    int pos = 0;
    while (pos < n) {
      if (loops[pos] < n - 1) {
        loops[pos]++;
        break;
      } else {
        loops[pos] = 0;
        pos++;
      }
    }
    if (pos == n) {
      break;
    }
  }

  int original[n];
  for (int i = 0; i < n; i++) {
    original[i] = arr[i];
  }
  for (int i = 0; i < n; i++) {
    arr[i] = original[indexes[i]];
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
