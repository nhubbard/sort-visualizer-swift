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

void findMinMax(int arr[], int a, int b, int *minValue, int *maxValue) {
  *minValue = arr[a];
  *maxValue = arr[a];
  for (int i = a + 1; i < b; i++) {
    if (arr[i] < *minValue) {
      *minValue = arr[i];
    } else if (arr[i] > *maxValue) {
      *maxValue = arr[i];
    }
  }
}

void insertionSortRange(int arr[], int s, int e) {
  for (int i = s + 1; i < e; i++) {
    int j = i;
    while (j > s && arr[j - 1] > arr[j]) {
      int tmp = arr[j - 1];
      arr[j - 1] = arr[j];
      arr[j] = tmp;
      j--;
    }
  }
}

void siftDown(int arr[], int s, int root, int size) {
  while (1) {
    int largest = root;
    int left = 2 * root + 1;
    int right = 2 * root + 2;
    if (left < size && arr[s + largest] < arr[s + left]) {
      largest = left;
    }
    if (right < size && arr[s + largest] < arr[s + right]) {
      largest = right;
    }
    if (largest == root) break;
    int tmp = arr[s + root];
    arr[s + root] = arr[s + largest];
    arr[s + largest] = tmp;
    root = largest;
  }
}

void heapSortRange(int arr[], int s, int e) {
  int size = e - s;
  if (size <= 1) return;
  int i = size / 2 - 1;
  while (i >= 0) {
    siftDown(arr, s, i, size);
    i--;
  }
  int end = size - 1;
  while (end > 0) {
    int tmp = arr[s];
    arr[s] = arr[s + end];
    arr[s + end] = tmp;
    siftDown(arr, s, 0, end);
    end--;
  }
}

int classify(int value, int minValue, double c) {
  return (int)((value - minValue) * c);
}

void staticSort(int arr[], int a, int b) {
  int minValue, maxValue;
  findMinMax(arr, a, b, &minValue, &maxValue);
  int auxLen = b - a;
  int *count = calloc(auxLen + 1, sizeof(int));
  int *offset = calloc(auxLen + 1, sizeof(int));
  double c = (double)auxLen / (maxValue - minValue + 1);

  for (int i = a; i < b; i++) {
    int idx = classify(arr[i], minValue, c);
    count[idx] += 1;
  }

  offset[0] = a;
  for (int i = 1; i < auxLen; i++) {
    offset[i] = count[i - 1] + offset[i - 1];
  }

  for (int v = 0; v < auxLen; v++) {
    while (count[v] > 0) {
      int origin = offset[v];
      int from = origin;
      int num = arr[from];
      arr[from] = -1;
      do {
        int idx = classify(num, minValue, c);
        int to = offset[idx];
        offset[idx] += 1;
        count[idx] -= 1;
        int temp = arr[to];
        arr[to] = num;
        num = temp;
        from = to;
      } while (from != origin);
    }
  }

  for (int i = 0; i < auxLen; i++) {
    int s = (i > 1) ? offset[i - 1] : a;
    int e = offset[i];
    if (e - s <= 1) continue;
    if (e - s > 16) {
      heapSortRange(arr, s, e);
    } else {
      insertionSortRange(arr, s, e);
    }
  }

  free(count);
  free(offset);
}

void sort(int arr[], int n) {
  if (n > 1) {
    staticSort(arr, 0, n);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
