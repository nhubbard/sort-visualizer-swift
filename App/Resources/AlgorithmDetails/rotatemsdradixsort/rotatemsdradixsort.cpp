#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

int intPow(int base, int exponent);
int getDigit(int value, int place, int base);
void multiSwap(int arr[], int a, int b, int len);
void rotateBlocks(int arr[], int a, int m, int b);
int binSearchDigit(int arr[], int a, int b, int d, int place, int base);
void mergeDigit(int arr[], int a, int m, int b, int da, int db, int place,
                int base);
void mergeSortDigit(int arr[], int a, int b, int place, int base);
int shiftValue(int value, int places, int base);
int dist(int arr[], int a, int b, int place, int base);

void sort(int arr[], int n) {
  if (n <= 1) return;
  int base = 4, maxValue = 0;
  for (int j = 0; j < n; j++) if (arr[j] > maxValue) maxValue = arr[j];
  int q = 0, probe = base;
  while (probe <= maxValue) { q++; probe *= base; }
  int m = 0, i = 0, b = n;
  while (i < n) {
    int p = b - i < 1 ? i : dist(arr, i, b, q, base);
    if (q == 0) {
      m += base;
      int t = m / base;
      while (t % base == 0) { t /= base; q++; }
      i = b;
      while (b < n && shiftValue(arr[b], q + 1, base) == shiftValue(m, q + 1, base)) b++;
    } else { b = p; q--; }
  }
}

int intPow(int base, int exponent) {
  int result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}

int getDigit(int value, int place, int base) {
  return (value / intPow(base, place)) % base;
}

void multiSwap(int arr[], int a, int b, int len) {
  for (int i = 0; i < len; i++) {
    std::swap(arr[a + i], arr[b + i]);
  }
}

void rotateBlocks(int arr[], int a, int m, int b) {
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

int binSearchDigit(int arr[], int a, int b, int d, int place, int base) {
  while (a < b) {
    int mid = (a + b) / 2;
    if (getDigit(arr[mid], place, base) >= d) {
      b = mid;
    } else {
      a = mid + 1;
    }
  }
  return a;
}

void mergeDigit(int arr[], int a, int m, int b, int da, int db, int place,
                int base) {
  if (b - a < 2 || db - da < 2) {
    return;
  }
  int dm = (da + db) / 2;
  int m1 = binSearchDigit(arr, a, m, dm, place, base);
  int m2 = binSearchDigit(arr, m, b, dm, place, base);
  rotateBlocks(arr, m1, m, m2);
  int newM = m1 + (m2 - m);
  mergeDigit(arr, newM, m2, b, dm, db, place, base);
  mergeDigit(arr, a, m1, newM, da, dm, place, base);
}

void mergeSortDigit(int arr[], int a, int b, int place, int base) {
  if (b - a < 2) {
    return;
  }
  int mid = (a + b) / 2;
  mergeSortDigit(arr, a, mid, place, base);
  mergeSortDigit(arr, mid, b, place, base);
  mergeDigit(arr, a, mid, b, 0, base, place, base);
}

// Digit-sorts [a, b) in place by `place` using rotation instead of counting
// buckets, then recurses into every resulting digit bucket one place lower --
// an ordinary MSD radix sort built entirely out of the LSD variant's
// rotate/binary-search machinery.
int shiftValue(int value, int places, int base) {
  while (places-- > 0) value /= base;
  return value;
}

int dist(int arr[], int a, int b, int place, int base) {
  mergeSortDigit(arr, a, b, place, base);
  return binSearchDigit(arr, a, b, 1, place, base);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
