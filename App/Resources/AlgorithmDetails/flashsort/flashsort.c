#include <stdio.h>
#include <stdlib.h>

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

int classify(int value, int minValue, double c) {
  return (int)((value - minValue) * c) + 1;
}

void flashSort(int arr[], int n) {
  if (n == 0) return;

  int m = (int)(0.2 * n) + 2;

  int minValue = arr[0];
  int maxValue = arr[0];
  int maxIndex = 0;

  int i = 1;
  while (i < n - 1) {
    int small, big, bigIndex;
    if (arr[i] < arr[i + 1]) {
      small = arr[i]; big = arr[i + 1]; bigIndex = i + 1;
    } else {
      big = arr[i]; bigIndex = i; small = arr[i + 1];
    }
    if (big > maxValue) { maxValue = big; maxIndex = bigIndex; }
    if (small < minValue) { minValue = small; }
    i += 2;
  }

  int last = arr[n - 1];
  if (last < minValue) {
    minValue = last;
  } else if (last > maxValue) {
    maxValue = last;
    maxIndex = n - 1;
  }

  if (maxValue == minValue) return;

  int *L = calloc(m + 1, sizeof(int));
  double c = (m - 1.0) / (maxValue - minValue);

  for (int h = 0; h < n; h++) {
    int k = classify(arr[h], minValue, c);
    L[k] += 1;
  }

  for (int k = 2; k <= m; k++) {
    L[k] += L[k - 1];
  }

  int tmpSwap = arr[maxIndex];
  arr[maxIndex] = arr[0];
  arr[0] = tmpSwap;

  int j = 0;
  int k = m;
  int numMoves = 0;
  while (numMoves < n) {
    while (j >= L[k]) {
      j++;
      k = classify(arr[j], minValue, c);
    }

    int evicted = arr[j];
    while (j < L[k]) {
      k = classify(evicted, minValue, c);
      int location = L[k] - 1;
      int temp = arr[location];
      arr[location] = evicted;
      evicted = temp;
      L[k] -= 1;
      numMoves++;
    }
  }

  for (int idx = 1; idx < n; idx++) {
    int current = arr[idx];
    int pos = idx - 1;
    while (pos >= 0 && arr[pos] > current) {
      arr[pos + 1] = arr[pos];
      pos--;
    }
    arr[pos + 1] = current;
  }

  free(L);
}

void sort(int arr[], int n) {
  flashSort(arr, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
