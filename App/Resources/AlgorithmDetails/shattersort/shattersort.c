#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

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

void insertionSort(int arr[], int start, int end) {
  for (int i = start + 1; i < end; i++) {
    int key = arr[i];
    int j = i - 1;
    while (j >= start && arr[j] > key) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[j + 1] = key;
  }
}

int *shatterPartition(int arr[], int start, int length, int num, int *outShatters) {
  int minV = arr[start];
  int maxV = arr[start];
  for (int i = 1; i < length; i++) {
    if (arr[start + i] < minV) minV = arr[start + i];
    if (arr[start + i] > maxV) maxV = arr[start + i];
  }
  int valueRange = maxV - minV + 1;
  int shatters = (length + num - 1) / num;

  int **buckets = malloc(shatters * sizeof(int *));
  int *counts = calloc(shatters, sizeof(int));
  for (int i = 0; i < shatters; i++) {
    buckets[i] = malloc(length * sizeof(int));
  }

  for (int i = 0; i < length; i++) {
    int v = arr[start + i];
    int idx = (v - minV) * shatters / valueRange;
    if (idx > shatters - 1) idx = shatters - 1;
    buckets[idx][counts[idx]++] = v;
  }

  int *offsets = malloc((shatters + 1) * sizeof(int));
  offsets[0] = 0;
  for (int i = 0; i < shatters; i++) {
    offsets[i + 1] = offsets[i] + counts[i];
  }

  int pos = start;
  for (int i = 0; i < shatters; i++) {
    for (int j = 0; j < counts[i]; j++) {
      arr[pos++] = buckets[i][j];
    }
    free(buckets[i]);
  }
  free(buckets);
  free(counts);

  *outShatters = shatters;
  return offsets;
}

void shatterSort(int arr[], int length, int num) {
  int shatters;
  int *offsets = shatterPartition(arr, 0, length, num, &shatters);
  for (int i = 0; i < shatters; i++) {
    if (offsets[i + 1] - offsets[i] > 1) {
      insertionSort(arr, offsets[i], offsets[i + 1]);
    }
  }
  free(offsets);
}

void sort(int arr[], int n) {
  shatterSort(arr, n, 4);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
