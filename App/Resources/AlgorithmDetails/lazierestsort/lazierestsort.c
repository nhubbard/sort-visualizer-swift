#include <stdio.h>
#include <stdlib.h>

int array[24] = {0,  39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81,
                 68, 83, 32, 56, 10, 2,  95, 46, 21, 74, 6,  38};

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

int smaller(int a, int b) { return a < b ? a : b; }
int larger(int a, int b) { return a > b ? a : b; }

void reverse(int arr[], int a, int b) {
  b--;
  while (a < b)
    swap(&arr[a++], &arr[b--]);
}

void rotate(int arr[], int a, int m, int b) {
  reverse(arr, a, m);
  reverse(arr, m, b);
  reverse(arr, a, b);
}

int search(int arr[], int a, int b, int value, int upper) {
  while (a < b) {
    int mid = (a + b) / 2;
    if (value < arr[mid] || (!upper && value == arr[mid]))
      b = mid;
    else
      a = mid + 1;
  }
  return a;
}

int gallop(int arr[], int a, int b, int value, int backwards) {
  int step = 1;
  if (backwards) {
    while (b - step >= a && value < arr[b - step])
      step *= 2;
    return search(arr, larger(a, b - step + 1), b - step / 2, value, 1);
  }
  while (a - 1 + step < b && value > arr[a - 1 + step])
    step *= 2;
  return search(arr, a + step / 2, smaller(b, a - 1 + step), value, 0);
}

void insertion(int arr[], int a, int b) {
  for (int i = a + 1; i < b; i++) {
    int value = arr[i];
    int position = search(arr, a, i, value, 1);
    for (int j = i; j > position; j--)
      arr[j] = arr[j - 1];
    arr[position] = value;
  }
}

void forward(int arr[], int a, int m, int b) {
  int i = a, j = m;
  while (i < j && j < b) {
    if (arr[i] > arr[j]) {
      int k = gallop(arr, j + 1, b, arr[i], 0);
      rotate(arr, i, j, k);
      i += k - j;
      j = k;
    } else
      i++;
  }
}

void backward(int arr[], int a, int m, int b) {
  int i = m - 1, j = b - 1;
  while (j > i && i >= a) {
    if (arr[i] > arr[j]) {
      int k = gallop(arr, a, i, arr[j], 1);
      rotate(arr, k, i + 1, j + 1);
      j -= i + 1 - k;
      i = k - 1;
    } else
      j--;
  }
}

void merge(int arr[], int a, int m, int b) {
  if (b - m < m - a)
    backward(arr, a, m, b);
  else
    forward(arr, a, m, b);
}

void fragmented(int arr[], int a, int m, int b, int size) {
  int i = a + (m - a) % size;
  while (i < m) {
    int j = gallop(arr, m, b, arr[i], 0);
    rotate(arr, i, m, j);
    int length = j - m, boundary = i;
    i += length;
    m += length;
    merge(arr, a, boundary, i);
    a = i;
    i += size;
  }
  merge(arr, larger(a, i - size), i, b);
}

void sort(int arr[], int n) {
  if (n <= 16) {
    insertion(arr, 0, n);
    return;
  }
  int size = 1;
  while (size * size * size < n)
    size++;
  int group = size * size;
  for (int i = n % size; i <= n; i += size)
    insertion(arr, larger(0, i - size), i);
  int i = n - size, j = n;
  while (i > 0) {
    if (j - i == group) {
      j -= group;
      i -= size;
    }
    forward(arr, larger(0, i - size), i, j);
    i -= size;
  }
  for (i = n - group; i > 0; i -= group)
    fragmented(arr, larger(0, i - group), i, n, size);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
