#include <cstdio>
#include <utility>

const int RADIX = 4;

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

static int counts[RADIX];
static int offsets[RADIX];

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

int getDigit(int value, int place) {
  for (int p = 0; p < place; p++) {
    value /= RADIX;
  }
  return value % RADIX;
}

int shiftValue(int value, int places) {
  for (int p = 0; p < places; p++) {
    value /= RADIX;
  }
  return value;
}

void bump(int digit) { counts[digit]++; }

// Turns the raw per-bucket counts already accumulated in `counts` into
// starting offsets, then places every element in [start, end) by
// following displacement cycles, one bucket at a time.
int distribute(int arr[], int start, int end, int place) {
  for (int i = 1; i < RADIX; i++) {
    counts[i] += counts[i - 1];
    offsets[i] = counts[i - 1];
  }

  for (int bucket = 0; bucket < RADIX - 1; bucket++) {
    int position = start + offsets[bucket];
    if (counts[bucket] > offsets[bucket]) {
      int held = arr[position];
      do {
        int digit = getDigit(held, place);
        counts[digit]--;
        int displaced = arr[start + counts[digit]];
        arr[start + counts[digit]] = held;
        held = displaced;
      } while (counts[bucket] > offsets[bucket]);
    }
  }

  int split = start + offsets[1];
  for (int i = 0; i < RADIX; i++) {
    counts[i] = 0;
    offsets[i] = 0;
  }
  return split;
}

void sort(int arr[], int n) {
  if (n < 2) {
    return;
  }

  int q = 0;
  int probe = RADIX;
  int maxValue = arr[0];
  for (int k = 1; k < n; k++) {
    if (arr[k] > maxValue) {
      maxValue = arr[k];
    }
  }
  while (probe <= maxValue) {
    q++;
    probe *= RADIX;
  }

  for (int i = 0; i < RADIX; i++) {
    counts[i] = 0;
    offsets[i] = 0;
  }

  // `i`/`b` track the bounds of whichever range is currently active, `q`
  // the digit place being distributed on, and `m` a counter that mirrors
  // how many bucket boundaries have already been walked at the current
  // depth, standing in for the call stack a recursive walk would need.
  int m = 0;
  int i = 0;
  int b = n;

  for (int j = i; j < b; j++) {
    bump(getDigit(arr[j], q));
  }

  while (i < n) {
    int p = (b - i < 1) ? i : distribute(arr, i, b, q);

    if (q == 0) {
      m += RADIX;
      int t = m / RADIX;
      while (t % RADIX == 0) {
        t /= RADIX;
        q++;
      }

      i = b;
      while (b < n && shiftValue(arr[b], q + 1) == shiftValue(m, q + 1)) {
        bump(getDigit(arr[b], q));
        b++;
      }
    } else {
      b = p;
      q--;
      for (int j = i; j < b; j++) {
        bump(getDigit(arr[j], q));
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
