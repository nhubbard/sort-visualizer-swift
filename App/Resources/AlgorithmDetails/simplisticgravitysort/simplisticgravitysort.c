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
  printf("[");
  if (size > 0) {
    printf("%d", items[0]);
    for (int i = 1; i < size; i++) {
      printf(", %d", items[i]);
    }
  }
  printf("]");
}

void transferTo(int arr[], int aux[], int minValue, int index);
void transferFrom(int arr[], int aux[], int auxLength, int index);

void sort(int arr[], int n) {
  if (n < 2)
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

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
