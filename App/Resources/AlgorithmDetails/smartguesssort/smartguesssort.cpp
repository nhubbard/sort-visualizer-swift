#include <cstdio>

int array[7] = {0, 39, 21, 62, 91, 14, 23};

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

bool pairOk(int arr[], int loops[], int i) {
  int a = arr[loops[i]];
  int b = arr[loops[i + 1]];
  if (a < b) {
    return true;
  }
  if (a == b && loops[i] < loops[i + 1]) {
    return true;
  }
  return false;
}

int firstFailure(int arr[], int loops[], int n) {
  int i = n - 2;
  while (i >= 0 && pairOk(arr, loops, i)) {
    i--;
  }
  return i;
}

void sort(int arr[], int n) {
  int loops[n];
  for (int i = 0; i < n; i++) {
    loops[i] = 0;
  }

  while (true) {
    int i = firstFailure(arr, loops, n);
    if (i < 0) {
      break;
    }
    for (int pos = 0; pos < n; pos++) {
      if (pos >= i && loops[pos] < n - 1) {
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
