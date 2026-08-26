#include <stdio.h>
#include <stdlib.h>

#define RECENCY 8
#define EARLY_OUT_TEST_AT 4
#define EARLY_OUT_DISORDER_FRACTION 0.6

int array[30] = {0,  1,  2,  3,  4,  9,  6,  7,  8,  5,  10, 11, 12, 13, 14,
                 15, 21, 17, 18, 19, 20, 16, 22, 23, 24, 28, 26, 27, 25, 29};

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

/* A plain general-purpose sort for arr[lo..hi), used both as the early-out
 * fallback and to sort the leftover "dropped" elements before the final merge.
 * Any decent O(n log n) sort works here -- the algorithm doesn't depend on
 * which one. */
void quicksort(int arr[], int lo, int hi) {
  if (hi - lo <= 1) {
    return;
  }
  int pivot = arr[lo + (hi - lo) / 2];
  int n = hi - lo;
  int *less = malloc(n * sizeof(int));
  int *equal = malloc(n * sizeof(int));
  int *greater = malloc(n * sizeof(int));
  int lessCount = 0, equalCount = 0, greaterCount = 0;

  for (int i = lo; i < hi; i++) {
    if (arr[i] < pivot) {
      less[lessCount++] = arr[i];
    } else if (arr[i] > pivot) {
      greater[greaterCount++] = arr[i];
    } else {
      equal[equalCount++] = arr[i];
    }
  }

  quicksort(less, 0, lessCount);
  quicksort(greater, 0, greaterCount);

  int k = lo;
  for (int i = 0; i < lessCount; i++) {
    arr[k++] = less[i];
  }
  for (int i = 0; i < equalCount; i++) {
    arr[k++] = equal[i];
  }
  for (int i = 0; i < greaterCount; i++) {
    arr[k++] = greater[i];
  }

  free(less);
  free(equal);
  free(greater);
}

void sort(int arr[], int length) {
  if (length < 2) {
    return;
  }

  /* `dropped` is grown one element at a time via droppedCount and shrunk during
   * backtrack by simply decrementing droppedCount -- it can never hold more
   * than `length` elements. */
  int *dropped = malloc(length * sizeof(int));
  int droppedCount = 0;
  int numDroppedInARow = 0;
  int read = 0;
  int write = 0;
  int iteration = 0;
  int earlyOutStop = length / EARLY_OUT_TEST_AT;

  while (read < length) {
    iteration++;
    if (iteration == earlyOutStop &&
        droppedCount > read * EARLY_OUT_DISORDER_FRACTION) {
      /* Too disordered for the adaptive approach to be worth it: flush what's
       * been dropped so far back into the array and fall back to a plain full
       * sort. */
      for (int i = 0; i < droppedCount; i++) {
        arr[write] = dropped[i];
        write++;
      }
      droppedCount = 0;
      quicksort(arr, 0, length);
      free(dropped);
      return;
    }

    if (write == 0 || arr[read] >= arr[write - 1]) {
      /* In order -- keep it. */
      arr[write] = arr[read];
      write++;
      read++;
      numDroppedInARow = 0;
    } else if (numDroppedInARow == 0 && write >= 2 &&
               arr[read] >= arr[write - 2]) {
      /* Quick undo: the element two back would have accepted this one just
       * fine, so drop the one right before it instead of the new element. */
      dropped[droppedCount++] = arr[write - 1];
      arr[write - 1] = arr[read];
      read++;
    } else if (numDroppedInARow < RECENCY) {
      dropped[droppedCount++] = arr[read];
      read++;
      numDroppedInARow++;
    } else {
      /* Accepting something `numDroppedInARow` elements back made every
       * subsequent element drop -- that accept was a mistake. Undo it, and any
       * other recently accepted elements bigger than the dropped run's maximum.
       */
      droppedCount -= numDroppedInARow;
      read -= numDroppedInARow;

      int numBacktracked = 1;
      write--;

      int maxOfDropped = arr[read];
      for (int i = read + 1; i <= read + numDroppedInARow; i++) {
        if (arr[i] > maxOfDropped) {
          maxOfDropped = arr[i];
        }
      }

      while (write >= 1 && maxOfDropped < arr[write - 1]) {
        write--;
        numBacktracked++;
      }

      for (int i = write; i < write + numBacktracked; i++) {
        dropped[droppedCount++] = arr[i];
      }

      numDroppedInARow = 0;
    }
  }

  for (int offset = 0; offset < droppedCount; offset++) {
    arr[write + offset] = dropped[offset];
  }

  quicksort(arr, write, length);

  /* Copy the now-sorted dropped tail before the final backward merge starts
   * overwriting arr[write:] in place. */
  int *buffer = malloc(droppedCount * sizeof(int));
  for (int i = 0; i < droppedCount; i++) {
    buffer[i] = arr[write + i];
  }

  int i = droppedCount - 1;
  int j = write - 1;
  int k = length - 1;

  while (i >= 0) {
    if (j < 0 || buffer[i] > arr[j]) {
      arr[k] = buffer[i];
      k--;
      i--;
    } else {
      arr[k] = arr[j];
      k--;
      j--;
    }
  }

  free(buffer);
  free(dropped);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
