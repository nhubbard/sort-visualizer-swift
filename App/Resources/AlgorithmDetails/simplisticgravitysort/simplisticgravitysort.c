#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

void transferTo(int arr[], int aux[], int minValue, int index) {
  int pointer = 0;
  while (arr[index] > minValue) {
    arr[index]--;
    aux[pointer]++;
    pointer++;
  }
}

void transferFrom(int arr[], int aux[], int auxLength, int index) {
  int pointer = 0;
  while (pointer < auxLength && aux[pointer] != 0) {
    arr[index]++;
    aux[pointer]--;
    pointer++;
  }
}

void sort(int arr[], int n) {
  if (n == 0)
    return;

  int minValue = arr[0];
  int maxValue = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] < minValue)
      minValue = arr[i];
    if (arr[i] > maxValue)
      maxValue = arr[i];
  }
  int auxLength = maxValue - minValue;
  int *aux = calloc(auxLength, sizeof(int));

  for (int i = 0; i < n; i++) {
    transferTo(arr, aux, minValue, i);
  }
  for (int i = n - 1; i >= 0; i--) {
    transferFrom(arr, aux, auxLength, i);
  }

  free(aux);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
