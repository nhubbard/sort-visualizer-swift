#include <cstdio>
#include <vector>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

void sort(int arr[], int n) {
  int max = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] > max) {
      max = arr[i];
    }
  }

  std::vector<int> counts(max + 1, 0);
  for (int i = 0; i < n; i++) {
    counts[arr[i]]++;
  }
  for (int i = 1; i <= max; i++) {
    counts[i] += counts[i - 1];
  }

  std::vector<int> output(n);
  for (int i = n - 1; i >= 0; i--) {
    counts[arr[i]]--;
    output[counts[arr[i]]] = arr[i];
  }

  for (int i = 0; i < n; i++) {
    arr[i] = output[i];
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
