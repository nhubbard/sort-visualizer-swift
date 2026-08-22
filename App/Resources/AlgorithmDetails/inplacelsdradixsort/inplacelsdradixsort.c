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

int intPow(int base, int exponent) {
  int result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}

int getDigit(int value, int power, int radix) {
  return (value / intPow(radix, power)) % radix;
}

void multiSwap(int arr[], int pos, int to) {
  if (to > pos) {
    for (int k = pos; k < to; k++) {
      swap(&arr[k], &arr[k + 1]);
    }
  } else if (to < pos) {
    for (int k = pos; k > to; k--) {
      swap(&arr[k], &arr[k - 1]);
    }
  }
}

void sort(int arr[], int n) {
  if (n == 0) {
    return;
  }
  int radix = 4;
  int maxValue = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] > maxValue) {
      maxValue = arr[i];
    }
  }

  int maxPower = 0;
  int probe = radix;
  while (probe <= maxValue) {
    maxPower++;
    probe *= radix;
  }

  int vregs[radix - 1]; // one register per nonzero digit value (1..radix-1)

  for (int power = 0; power <= maxPower; power++) {
    for (int i = 0; i < radix - 1; i++) {
      vregs[i] = n - 1;
    }

    int pos = 0;
    for (int step = 0; step < n; step++) {
      int digit = getDigit(arr[pos], power, radix);
      if (digit == 0) {
        pos++;
      } else {
        int to = vregs[digit - 1];
        multiSwap(arr, pos, to);
        for (int j = digit - 1; j > 0; j--) {
          vregs[j - 1]--;
        }
      }
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
