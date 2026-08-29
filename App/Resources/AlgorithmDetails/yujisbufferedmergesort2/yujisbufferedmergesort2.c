#include <stdio.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

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

int ceilLog(int n) {
  int i = 0;
  while ((1 << i) < n) {
    i++;
  }
  return i;
}

void multiSwap(int arr[], int a, int b, int len) {
  for (int i = 0; i < len; i++) {
    swap(&arr[a + i], &arr[b + i]);
  }
}

void insertTo(int arr[], int a, int b) {
  int temp = arr[a];
  while (a > b) {
    a--;
    arr[a + 1] = arr[a];
  }
  arr[b] = temp;
}

int binarySearch(int arr[], int start, int end, int value, int left) {
  int a = start;
  int b = end;
  while (a < b) {
    int m = a + (b - a) / 2;
    int comp = left ? (value <= arr[m]) : (value < arr[m]);
    if (comp) {
      b = m;
    } else {
      a = m + 1;
    }
  }
  return a;
}

void binaryInsertion(int arr[], int a, int b) {
  int i = a + 1;
  while (i < b) {
    int value = arr[i];
    insertTo(arr, i, binarySearch(arr, a, i, value, 0));
    i++;
  }
}

int merge(int arr[], int a, int m, int b, int p) {
  int i = a;
  int j = m;
  while (i < m && j < b) {
    if (arr[i] <= arr[j]) {
      swap(&arr[p], &arr[i]);
      p++;
      i++;
    } else {
      swap(&arr[p], &arr[j]);
      p++;
      j++;
    }
  }
  int leftover = 0;
  while (i < m) {
    swap(&arr[p], &arr[i]);
    p++;
    i++;
  }
  while (j < b) {
    swap(&arr[p], &arr[j]);
    p++;
    j++;
    leftover++;
  }
  return leftover;
}

void mergeWithBufStatic(int arr[], int a, int m, int b, int p,
                        int useBinarySearch) {
  int i = 0;
  int j = m;
  int k = a;
  if (useBinarySearch) {
    while (i < m - a && j < b) {
      if (arr[j] < arr[p + i]) {
        int value = arr[p + i];
        int q = binarySearch(arr, j, b, value, 1);
        while (j < q) {
          swap(&arr[k], &arr[j]);
          k++;
          j++;
        }
      }
      swap(&arr[k], &arr[p + i]);
      k++;
      i++;
    }
    while (i < m - a) {
      swap(&arr[k], &arr[p + i]);
      k++;
      i++;
    }
  } else {
    while (i < m - a && j < b) {
      if (arr[p + i] <= arr[j]) {
        swap(&arr[k], &arr[p + i]);
        k++;
        i++;
      } else {
        swap(&arr[k], &arr[j]);
        k++;
        j++;
      }
    }
    while (i < m - a) {
      swap(&arr[k], &arr[p + i]);
      k++;
      i++;
    }
  }
}

void mergeSort(int arr[], int a, int p, int length) {
  int j = 16;
  int ceilLogValue = ceilLog(length);
  int pos = (length > 16 && (ceilLogValue & 1) == 1) ? p : a;

  int i = pos;
  while (i + 16 <= pos + length) {
    binaryInsertion(arr, i, i + 16);
    i += 16;
  }
  binaryInsertion(arr, i, pos + length);

  int nxt = pos;
  while (j < length) {
    pos = nxt;
    nxt ^= a ^ p;
    int posNext = nxt;

    i = pos;
    while (i + 2 * j <= pos + length) {
      merge(arr, i, i + j, i + 2 * j, posNext);
      i += 2 * j;
      posNext += 2 * j;
    }
    if (i + j < pos + length) {
      merge(arr, i, i + j, pos + length, posNext);
    } else {
      while (i < pos + length) {
        swap(&arr[i], &arr[posNext]);
        i++;
        posNext++;
      }
    }
    j *= 2;
  }
}

void bufferedMerge(int arr[], int a, int b) {
  if (b - a <= 16) {
    binaryInsertion(arr, a, b);
    return;
  }

  int m = (a + b + 1) / 2;
  mergeSort(arr, m, 2 * m - b, b - m);

  int n = (a + m + 1) / 2;
  int limit = (b - a) / 16;
  while (m - a > limit) {
    mergeSort(arr, 2 * n - m, n, m - n);
    mergeWithBufStatic(arr, n, m, b, 2 * n - m,
                       (b - m) / (m - n) >= ceilLog(n - a));
    m = n;
    n = (a + m + 1) / 2;
  }

  bufferedMerge(arr, a, m);
  multiSwap(arr, a, b - (m - a), m - a);
  int s = merge(arr, m, b - (m - a), b, a);
  bufferedMerge(arr, b - (m - a) - s, b);
}

void sort(int arr[], int n) {
  if (n <= 1) {
    return;
  }
  bufferedMerge(arr, 0, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
