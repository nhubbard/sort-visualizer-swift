#include <stdio.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

void insertTo(int arr[], int a, int b) {
  int temp = arr[a];
  while (a > b) {
    a--;
    arr[a + 1] = arr[a];
  }
  arr[b] = temp;
}

void multiSwap(int arr[], int a, int b, int len) {
  for (int i = 0; i < len; i++) {
    int temp = arr[a + i];
    arr[a + i] = arr[b + i];
    arr[b + i] = temp;
  }
}

void rotate(int arr[], int a, int m, int b) {
  int l = m - a;
  int r = b - m;
  while (l > 0 && r > 0) {
    if (r < l) {
      multiSwap(arr, m - r, m, r);
      b -= r;
      m -= r;
      l -= r;
    } else {
      multiSwap(arr, a, m, l);
      a += l;
      m += l;
      r -= l;
    }
  }
}

void bitReversal(int arr[], int a, int b) {
  int len = b - a;
  int m = 0;
  int d1 = len >> 1;
  int d2 = d1 + (d1 >> 1);
  int i = 1;
  while (i < len - 1) {
    int j = d1;
    int k = i;
    int nn = d2;
    while ((k & 1) == 0) {
      j -= nn;
      k >>= 1;
      nn >>= 1;
    }
    m += j;
    if (m > i) {
      int temp = arr[a + i];
      arr[a + i] = arr[a + m];
      arr[a + m] = temp;
    }
    i++;
  }
}

void weaveInsert(int arr[], int a, int b, int rightInit) {
  int right = rightInit;
  int i = a;
  int j = a + 1;
  while (j < b) {
    if (right) {
      while (i < j && arr[i] <= arr[j])
        i++;
    } else {
      while (i < j && arr[i] < arr[j])
        i++;
    }
    if (i == j) {
      right = !right;
      j++;
    } else {
      insertTo(arr, j, i);
      i++;
      j += 2;
    }
  }
}

void weaveMerge(int arr[], int a, int mInit, int b) {
  if (b - a < 2)
    return;
  int a1 = a;
  int b1 = b;
  int right = 1;
  if ((b - a) % 2 == 1) {
    if (mInit - a < b - mInit) {
      a1 -= 1;
      right = 0;
    } else {
      b1 += 1;
    }
  }
  int e = b1;
  while (e - a1 > 2) {
    int m = (a1 + e) / 2;
    int p = 1;
    while (p * 2 <= m - a1)
      p *= 2;
    rotate(arr, m - p, m, e - p);
    m = e - p;
    int f = m - p;
    bitReversal(arr, f, m);
    bitReversal(arr, m, e);
    bitReversal(arr, f, e);
    e = f;
  }
  weaveInsert(arr, a, b, right);
}

void sort(int arr[], int size) {
  int n = size;
  if (n <= 1)
    return;
  int d = 1;
  while (d < n)
    d <<= 1;
  while (d > 1) {
    int i = 0;
    int dec = 0;
    while (i < n) {
      int j = i;
      dec += n;
      while (dec >= d) {
        dec -= d;
        j++;
      }
      int k = j;
      dec += n;
      while (dec >= d) {
        dec -= d;
        k++;
      }
      weaveMerge(arr, i, j, k);
      i = k;
    }
    d /= 2;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
