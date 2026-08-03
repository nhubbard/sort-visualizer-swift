#include <limits.h>
#include <stdio.h>
#include <stdlib.h>

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

#define EMPTY INT_MIN

typedef struct {
  int *slots;
  int capacity;
  int *positions;
  int count;
} LibraryState;

static void rebalance(LibraryState *state) {
  int count = state->count;
  int newCapacity = count * 2 > 2 ? count * 2 : 2;
  int *newSlots = malloc(sizeof(int) * (size_t)newCapacity);
  for (int i = 0; i < newCapacity; i++) {
    newSlots[i] = EMPTY;
  }
  for (int i = 0; i < count; i++) {
    int pos = state->positions[i];
    int newPos = i * 2;
    newSlots[newPos] = state->slots[pos];
    state->positions[i] = newPos;
  }
  free(state->slots);
  state->slots = newSlots;
  state->capacity = newCapacity;
}

static void positionsInsert(LibraryState *state, int index, int value) {
  for (int i = state->count; i > index; i--) {
    state->positions[i] = state->positions[i - 1];
  }
  state->positions[index] = value;
  state->count++;
}

static void insertValue(LibraryState *state, int value) {
  if (state->count == state->capacity) {
    rebalance(state);
  }

  /* Upper-bound binary search: first slot whose value is strictly greater than
   * `value`. */
  int lo = 0;
  int hi = state->count;
  while (lo < hi) {
    int mid = (lo + hi) / 2;
    if (state->slots[state->positions[mid]] > value) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  int k = lo;
  int targetPos = k == 0 ? 0 : state->positions[k - 1] + 1;

  if (!(targetPos == state->capacity || state->slots[targetPos] != EMPTY)) {
    state->slots[targetPos] = value;
    positionsInsert(state, k, targetPos);
    return;
  }

  /* Either targetPos is already occupied, or targetPos == capacity (new
   * maximum, no room left of the structure's end). Search BOTH directions for
   * the nearest gap and shift whichever side is closer. */
  int leftGap = targetPos - 1;
  while (leftGap >= 0 && state->slots[leftGap] != EMPTY) {
    leftGap--;
  }
  int rightGap = targetPos;
  while (rightGap < state->capacity && state->slots[rightGap] != EMPTY) {
    rightGap++;
  }
  int leftDistance = leftGap >= 0 ? targetPos - leftGap : INT_MAX;
  int rightDistance =
      rightGap < state->capacity ? rightGap - targetPos : INT_MAX;

  if (rightDistance <= leftDistance) {
    int i = rightGap;
    while (i > targetPos) {
      state->slots[i] = state->slots[i - 1];
      i--;
    }
    for (int idx = k; idx < k + (rightGap - targetPos); idx++) {
      state->positions[idx]++;
    }
    state->slots[targetPos] = value;
    positionsInsert(state, k, targetPos);
  } else {
    int shiftCount = (targetPos - 1) - leftGap;
    int i = leftGap;
    while (i < targetPos - 1) {
      state->slots[i] = state->slots[i + 1];
      i++;
    }
    for (int idx = k - shiftCount; idx < k; idx++) {
      state->positions[idx]--;
    }
    state->slots[targetPos - 1] = value;
    positionsInsert(state, k, targetPos - 1);
  }
}

void sort(int arr[], int n) {
  if (n <= 1) {
    return;
  }

  LibraryState state = {NULL, 0, malloc(sizeof(int) * (size_t)n), 0};

  for (int i = 0; i < n; i++) {
    insertValue(&state, arr[i]);
  }

  for (int i = 0; i < n; i++) {
    arr[i] = state.slots[state.positions[i]];
  }

  free(state.slots);
  free(state.positions);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
