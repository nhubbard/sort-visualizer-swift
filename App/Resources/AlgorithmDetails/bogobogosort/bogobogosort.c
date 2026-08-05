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

/* A literal Bogo Bogo Sort re-derives the "is it sorted?" answer through a
 * recursive sort of its own, so its real cost grows worse than n! squared --
 * even a handful of elements can take an unreasonable amount of time. To keep
 * this example runnable, the true recursive algorithm below is only ever
 * applied to a small leading slice of the array (CHAOS_LIMIT elements); the
 * rest is finished with an ordinary insertion sort, and the two already-sorted
 * pieces are merged back together at the end. The random reshuffle is also
 * replaced with a deterministic, never-repeating permutation walk, so neither
 * piece can wander into an unbounded random search. */
#define CHAOS_LIMIT 5

/* Advances arr[0..n) to its next lexicographic permutation in place. Returns 0
 * (after resetting arr to its first, fully ascending permutation) once every
 * arrangement has been visited -- a deterministic stand-in for "shuffle the
 * array at random". */
int nextPermutation(int *arr, int n) {
  int i = n - 2;
  while (i >= 0 && arr[i] >= arr[i + 1]) {
    i--;
  }
  if (i < 0) {
    for (int lo = 0, hi = n - 1; lo < hi; lo++, hi--) {
      swap(&arr[lo], &arr[hi]);
    }
    return 0;
  }
  int j = n - 1;
  while (arr[j] <= arr[i]) {
    j--;
  }
  swap(&arr[i], &arr[j]);
  for (int lo = i + 1, hi = n - 1; lo < hi; lo++, hi--) {
    swap(&arr[lo], &arr[hi]);
  }
  return 1;
}

void bogoBogoSort(int *arr, int n);

/* The heart of the joke: rather than scanning arr once, decide whether it is
 * sorted by copying it, recursively Bogo-Bogo-sorting the copy's first n - 1
 * elements with this exact same process one level down, reshuffling the whole
 * copy until its last two elements land in order, and comparing the result
 * against the original. A match means the copy is now the true sorted
 * arrangement of the same values, which is only possible if arr was already
 * sorted. */
int bogoBogoIsSorted(int *arr, int n) {
  if (n <= 1) {
    return 1;
  }
  int copy[CHAOS_LIMIT];
  for (int k = 0; k < n; k++) {
    copy[k] = arr[k];
  }
  bogoBogoSort(copy, n - 1);
  int candidate = 0;
  while (copy[n - 2] > copy[n - 1]) {
    swap(&copy[candidate], &copy[n - 1]);
    candidate++;
    bogoBogoSort(copy, n - 1);
  }
  for (int k = 0; k < n; k++) {
    if (copy[k] != arr[k]) {
      return 0;
    }
  }
  return 1;
}

void bogoBogoSort(int *arr, int n) {
  while (!bogoBogoIsSorted(arr, n)) {
    nextPermutation(arr, n);
  }
}

void insertionSort(int *arr, int n) {
  for (int i = 1; i < n; i++) {
    int key = arr[i];
    int j = i - 1;
    while (j >= 0 && arr[j] > key) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[j + 1] = key;
  }
}

void mergeSorted(int *a, int aLen, int *b, int bLen, int *out) {
  int i = 0, j = 0, k = 0;
  while (i < aLen && j < bLen) {
    if (a[i] <= b[j]) {
      out[k++] = a[i++];
    } else {
      out[k++] = b[j++];
    }
  }
  while (i < aLen) {
    out[k++] = a[i++];
  }
  while (j < bLen) {
    out[k++] = b[j++];
  }
}

void sort(int arr[], int n) {
  int limit = n < CHAOS_LIMIT ? n : CHAOS_LIMIT;
  int chaos[CHAOS_LIMIT];
  for (int k = 0; k < limit; k++) {
    chaos[k] = arr[k];
  }
  int restLen = n - limit;
  int *rest = malloc(sizeof(int) * (restLen > 0 ? restLen : 1));
  for (int k = 0; k < restLen; k++) {
    rest[k] = arr[limit + k];
  }

  bogoBogoSort(
      chaos,
      limit); /* the real, recursive-check algorithm -- kept tiny on purpose */
  insertionSort(rest,
                restLen); /* an ordinary fast sort for the rest of the array */

  mergeSorted(chaos, limit, rest, restLen, arr);
  free(rest);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
