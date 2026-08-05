#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

/* Base case below length 12: repeatedly swap the minimum of the remaining
 * range to the front. */
void selectionSort(int arr[], int a, int b) {
  while (b > 1) {
    int k = 0;
    for (int i = 1; i < b; i++) {
      if (arr[a + k] > arr[a + i]) {
        k = i;
      }
    }
    swap(&arr[a], &arr[a + k]);
    a++;
    b--;
  }
}

/* Forward block-swap of l elements. */
void aswap(int arr[], int arr1, int arr2, int l) {
  while (l > 0) {
    swap(&arr[arr1], &arr[arr2]);
    arr1++;
    arr2++;
    l--;
  }
}

/* Merges the two runs ending at arr1/arr2 (lengths l1/l2), working backward
 * from their high ends into the trailing buffer that starts right after
 * arr2. Returns the count of unplaced left-run elements if the right run
 * ran out first (0 otherwise). */
int backmerge(int arr[], int arr1, int l1, int arr2, int l2) {
  int arr0 = arr2 + l1;
  while (1) {
    if (arr[arr1] > arr[arr2]) {
      swap(&arr[arr1], &arr[arr0]);
      arr1--;
      arr0--;
      l1--;
      if (l1 == 0) {
        return 0;
      }
    } else {
      swap(&arr[arr2], &arr[arr0]);
      arr2--;
      arr0--;
      l2--;
      if (l2 == 0) {
        break;
      }
    }
  }
  int res = l1;
  do {
    swap(&arr[arr1], &arr[arr0]);
    arr1--;
    arr0--;
    l1--;
  } while (l1 != 0);
  return res;
}

/* Merges arr[a..a+l) (as l/r blocks of width r) using the buffer
 * arr[a+l..a+l+r): selection-sorts the block leaders, then backmerges each
 * selected block into place. */
void rmerge(int arr[], int a, int l, int r) {
  int i = 0;
  while (i < l) {
    int q = i;
    int j = i + r;
    while (j < l) {
      if (arr[a + q] > arr[a + j]) {
        q = j;
      }
      j += r;
    }
    if (q != i) {
      aswap(arr, a + i, a + q, r);
    }
    if (i != 0) {
      aswap(arr, a + l, a + i, r);
      backmerge(arr, a + (l + r - 1), r, a + (i - 1), r);
    }
    i += r;
  }
}

/* Computes the block size: roughly sqrt(len), rounded up to a power of two. */
int rbnd(int len) {
  len /= 2;
  int k = 0;
  int i = 1;
  while (i < len) {
    k++;
    i *= 2;
  }
  len /= k;
  k = 1;
  while (k <= len) {
    k *= 2;
  }
  return k;
}

void msort(int arr[], int a, int len) {
  if (len < 12) {
    selectionSort(arr, a, len);
    return;
  }

  int r = rbnd(len);
  int lr = (len / r - 1) * r;

  int p = 2;
  while (p <= lr) {
    if (arr[a + (p - 2)] > arr[a + (p - 1)]) {
      swap(&arr[a + (p - 2)], &arr[a + (p - 1)]);
    }
    if ((p & 2) != 0) {
      p += 2;
      continue;
    }

    aswap(arr, a + (p - 2), a + p, 2);

    int m = len - p;
    int q = 2;
    while (1) {
      int q0 = 2 * q;
      if (q0 > m || (p & q0) != 0) {
        break;
      }
      backmerge(arr, a + (p - q - 1), q, a + (p + q - 1), q);
      q = q0;
    }
    backmerge(arr, a + (p + q - 1), q, a + (p - q - 1), q);
    int q1 = q;
    q *= 2;

    while ((q & p) == 0) {
      q *= 2;
      rmerge(arr, a + (p - q), q, q1);
    }

    p += 2;
  }

  int q1 = 0;
  int q = r;
  while (q < lr) {
    if ((lr & q) != 0) {
      q1 += q;
      if (q1 != q) {
        rmerge(arr, a + (lr - q1), q1, r);
      }
    }
    q *= 2;
  }

  int s0 = len - lr;
  msort(arr, a + lr, s0);
  aswap(arr, a, a + lr, s0);
  int s = s0 + backmerge(arr, a + (s0 - 1), s0, a + (lr - 1), lr - s0);
  msort(arr, a, s);
}

void sort(int arr[], int n) { msort(arr, 0, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
