#include <stdio.h>

static const long leonardo[21] = {1,    1,    3,    5,    9,    15,    25,
                                  41,   67,   109,  177,  287,  465,   753,
                                  1219, 1973, 3193, 5167, 8361, 13529, 21891};

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

int trailingZeroCount(long value) {
  long mask = value & ~1L;
  int trail = 0;
  while (mask != 0 && (mask & 1) == 0) {
    mask >>= 1;
    trail++;
  }
  return trail;
}

void sift(int arr[], int pshiftIn, int headIn) {
  int pshift = pshiftIn;
  int head = headIn;
  int val = arr[head];
  while (pshift > 1) {
    int rt = head - 1;
    int lf = head - 1 - (int)leonardo[pshift - 2];
    if (val >= arr[lf] && val >= arr[rt]) {
      break;
    }
    if (arr[lf] >= arr[rt]) {
      arr[head] = arr[lf];
      head = lf;
      pshift -= 1;
    } else {
      arr[head] = arr[rt];
      head = rt;
      pshift -= 2;
    }
  }
  arr[head] = val;
}

void trinkle(int arr[], long pIn, int pshiftIn, int headIn, int isTrustyIn) {
  long p = pIn;
  int pshift = pshiftIn;
  int head = headIn;
  int isTrusty = isTrustyIn;
  int val = arr[head];
  while (p != 1) {
    int stepson = head - (int)leonardo[pshift];
    if (arr[stepson] <= val) {
      break;
    }
    if (!isTrusty && pshift > 1) {
      int rt = head - 1;
      int lf = head - 1 - (int)leonardo[pshift - 2];
      if (arr[rt] >= arr[stepson] || arr[lf] >= arr[stepson]) {
        break;
      }
    }
    arr[head] = arr[stepson];
    head = stepson;
    int trail = trailingZeroCount(p);
    p >>= trail;
    pshift += trail;
    isTrusty = 0;
  }
  if (!isTrusty) {
    arr[head] = val;
    sift(arr, pshift, head);
  }
}

void sort(int arr[], int n) {
  if (n <= 1) {
    return;
  }

  int head = 0;
  long p = 1;
  int pshift = 1;
  int hi = n - 1;

  while (head < hi) {
    if ((p & 3) == 3) {
      sift(arr, pshift, head);
      p >>= 2;
      pshift += 2;
    } else {
      if (leonardo[pshift - 1] >= hi - head) {
        trinkle(arr, p, pshift, head, 0);
      } else {
        sift(arr, pshift, head);
      }
      if (pshift == 1) {
        p <<= 1;
        pshift -= 1;
      } else {
        p <<= (pshift - 1);
        pshift = 1;
      }
    }
    p |= 1;
    head += 1;
  }

  trinkle(arr, p, pshift, head, 0);
  while (pshift != 1 || p != 1) {
    if (pshift <= 1) {
      int trail = trailingZeroCount(p);
      p >>= trail;
      pshift += trail;
    } else {
      p <<= 2;
      p ^= 7;
      pshift -= 2;
      trinkle(arr, p >> 1, pshift + 1, head - (int)leonardo[pshift] - 1, 1);
      trinkle(arr, p, pshift, head - 1, 1);
    }
    head -= 1;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
