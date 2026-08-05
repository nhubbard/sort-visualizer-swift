#include <cstdio>
#include <utility>

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

// Reverses arr[0..hi] in place. This "flip" is the only move the algorithm ever
// performs; there is no per-element shift anywhere.
void flip(int arr[], int hi) {
  int lo = 0;
  while (lo < hi) {
    std::swap(arr[lo], arr[hi]);
    lo++;
    hi--;
  }
}

// Monobound binary search: locates the index within the ascending run
// arr[start..end) at which arr[valueIndex] belongs, using one comparison per
// halving instead of the usual two.
int searchAscending(int arr[], int start, int end, int valueIndex) {
  int top = end - start;
  while (top > 1) {
    int mid = top / 2;
    if (arr[valueIndex] <= arr[end - mid]) {
      end -= mid;
    }
    top -= mid;
  }
  if (arr[valueIndex] <= arr[end - 1]) {
    return end - 1;
  }
  return end;
}

// Mirror image of searchAscending for a descending run arr[start..end).
int searchDescending(int arr[], int start, int end, int valueIndex) {
  int top = end - start;
  while (top > 1) {
    int mid = top / 2;
    if (arr[start + mid] > arr[valueIndex]) {
      start += mid;
    }
    top -= mid;
  }
  if (arr[start] > arr[valueIndex]) {
    return start + 1;
  }
  return start;
}

// Hand-sorts arr[0..n) for n <= 3 via a small decision tree. Returns true if
// the result runs ascending, false if it runs descending.
bool sortFirstThree(int arr[], int n) {
  if (n < 2) {
    return false;
  }
  if (arr[0] > arr[1]) {
    flip(arr, 1);
  }
  if (n > 2) {
    if (arr[1] > arr[2]) {
      if (arr[0] > arr[2]) {
        flip(arr, 1);
      } else {
        flip(arr, 2);
        flip(arr, 1);
      }
      return false;
    }
    return true;
  }
  return true;
}

void sort(int arr[], int n) {
  if (n < 2) {
    return;
  }

  bool ascending = sortFirstThree(arr, n);

  for (int i = 3; i < n; i++) {
    if (ascending) {
      if (arr[i - 1] <= arr[i]) {
        // Already fits; the ascending prefix already ends at or below the new
        // element.
        continue;
      }
      if (arr[0] > arr[i]) {
        // The new element is smaller than everything in the prefix -- one flip
        // turns the whole thing, including the new element, into a descending
        // run.
        flip(arr, i - 1);
        ascending = false;
        continue;
      }
      int idx = searchAscending(arr, 0, i, i);
      flip(arr, i);
      int tail = i - idx;
      flip(arr, tail);
      flip(arr, tail - 1);
      ascending = false;
    } else {
      if (arr[i - 1] > arr[i]) {
        continue;
      }
      if (arr[0] <= arr[i]) {
        flip(arr, i - 1);
        ascending = true;
        continue;
      }
      int idx = searchDescending(arr, 0, i, i);
      flip(arr, i);
      int tail = i - idx;
      flip(arr, tail);
      flip(arr, tail - 1);
      ascending = true;
    }
  }

  if (!ascending) {
    flip(arr, n - 1);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
