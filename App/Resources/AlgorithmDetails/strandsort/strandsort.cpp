#include <cstdio>

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

void mergeTo(int arr[], int subList[], int a, int m, int b) {
  int i = 0;
  int s = m - a;
  while (i < s && m < b) {
    if (subList[i] < arr[m]) {
      arr[a] = subList[i];
      a++;
      i++;
    } else {
      arr[a] = arr[m];
      a++;
      m++;
    }
  }
  while (i < s) {
    arr[a] = subList[i];
    a++;
    i++;
  }
}

void sort(int arr[], int n) {
  if (n < 2)
    return;

  int *subList = new int[n];

  int j = n;
  int k = j;
  while (j > 0) {
    subList[0] = arr[0];
    k--;

    int i = 0;
    int p = 0;
    for (int m = 1; m < j; m++) {
      if (arr[m] >= subList[i]) {
        i++;
        subList[i] = arr[m];
        k--;
      } else {
        arr[p] = arr[m];
        p++;
      }
    }

    mergeTo(arr, subList, k, j, n);
    j = k;
  }

  delete[] subList;
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
