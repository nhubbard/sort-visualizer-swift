#include <cstdio>
#include <utility>
#include <vector>

static int blockSize = 1;

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

void multiSwap(int arr[], int a, int b, int len);
void rotate(int arr[], int a, int m, int b);
int binarySearch(int arr[], int a, int b, int value, bool left);
void sqrtMerge(int arr[], int a, int m, int b);
void sqrtSort(int arr[], int a, int b);

void sort(int arr[], int n) {
  blockSize = 1;
  while (blockSize * blockSize < n)
    blockSize *= 2;
  sqrtSort(arr, 0, n);
}

void multiSwap(int arr[], int a, int b, int len) {
  for (int i = 0; i < len; i++) {
    std::swap(arr[a + i], arr[b + i]);
  }
}

void rotate(int arr[], int a, int m, int b) {
  int l = m - a, r = b - m;
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

int binarySearch(int arr[], int a, int b, int value, bool left) {
  while (a < b) {
    int mid = a + (b - a) / 2;
    bool comp = left ? (value <= arr[mid]) : (value < arr[mid]);
    if (comp) {
      b = mid;
    } else {
      a = mid + 1;
    }
  }
  return a;
}

void sqrtMerge(int arr[], int a, int m, int b) {
  if (a >= m || m >= b)
    return;
  if (m - a <= blockSize && b - m <= blockSize) {
    std::vector<int> temp(b - a, 0);
    for (int i = a; i < b; i++)
      temp[i - a] = arr[i];
    int i = 0, j = m - a, k = a;
    while (i < m - a && j < b - a) {
      if (temp[i] <= temp[j])
        arr[k++] = temp[i++];
      else
        arr[k++] = temp[j++];
    }
    while (i < m - a)
      arr[k++] = temp[i++];
    while (j < b - a)
      arr[k++] = temp[j++];
    return;
  }
  int m1, m2, m3;
  if (m - a >= b - m) {
    m1 = a + (m - a) / 2;
    int value = arr[m1];
    m2 = binarySearch(arr, m, b, value, true);
    m3 = m1 + (m2 - m);
  } else {
    m2 = m + (b - m) / 2;
    int value = arr[m2];
    m1 = binarySearch(arr, a, m, value, false);
    m3 = m2 - (m - m1);
    m2 = m2 + 1;
  }
  rotate(arr, m1, m, m2);
  if (m2 - (m3 + 1) > 0 && b - m2 > 0) {
    sqrtMerge(arr, m3 + 1, m2, b);
  }
  if (m1 - a > 0 && m3 - m1 > 0) {
    sqrtMerge(arr, a, m1, m3);
  }
}

void sqrtSort(int arr[], int a, int b) {
  int len = b - a;
  for (int start = a; start < b; start += 32) {
    int end = start + 32 < b ? start + 32 : b;
    for (int i = start + 1; i < end; i++) {
      int value = arr[i], j = i;
      while (j > start && arr[j - 1] > value) {
        arr[j] = arr[j - 1];
        j--;
      }
      arr[j] = value;
    }
  }
  int j = 32;
  while (j < len) {
    int i;
    for (i = a; i + 2 * j <= b; i += 2 * j) {
      sqrtMerge(arr, i, i + j, i + 2 * j);
    }
    if (i + j < b) {
      sqrtMerge(arr, i, i + j, b);
    }
    j *= 2;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
