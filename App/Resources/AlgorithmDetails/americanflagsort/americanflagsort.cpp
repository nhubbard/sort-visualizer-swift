#include <cstdio>
#include <vector>

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

int digitAt(int value, int divisor, int radix) {
  return (value / divisor) % radix;
}

void flagSort(int arr[], int low, int high, int divisor, int radix) {
  if (high - low <= 1) {
    return;
  }

  std::vector<int> count(radix, 0);
  std::vector<int> offset(radix, 0);

  for (int i = low; i < high; i++) {
    count[digitAt(arr[i], divisor, radix)]++;
  }

  offset[0] = low;
  for (int d = 1; d < radix; d++) {
    offset[d] = offset[d - 1] + count[d - 1];
  }
  std::vector<int> bucketStart = offset;

  for (int d = 0; d < radix; d++) {
    while (count[d] > 0) {
      int origin = offset[d];
      int from = origin;
      int value = arr[from];

      do {
        int digit = digitAt(value, divisor, radix);
        int dest = offset[digit]++;
        count[digit]--;
        int displaced = arr[dest];
        arr[dest] = value;
        value = displaced;
        from = dest;
      } while (from != origin);
    }
  }

  if (divisor > 1) {
    for (int d = 0; d < radix; d++) {
      int begin = bucketStart[d];
      int end = offset[d];
      if (end - begin > 1) {
        flagSort(arr, begin, end, divisor / radix, radix);
      }
    }
  }
}

void sort(int arr[], int n) {
  if (n <= 1) {
    return;
  }

  int radix = 10;
  int maxValue = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] > maxValue) {
      maxValue = arr[i];
    }
  }

  int divisor = 1;
  while (maxValue / divisor >= radix) {
    divisor *= radix;
  }

  flagSort(arr, 0, n, divisor, radix);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}