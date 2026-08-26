#include <cstdio>
#include <vector>

constexpr int kRecency = 8;
constexpr int kEarlyOutTestAt = 4;
constexpr double kEarlyOutDisorderFraction = 0.6;

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

// A plain general-purpose sort for arr[lo..hi), used both as the early-out
// fallback and to sort the leftover "dropped" elements before the final merge.
// Any decent O(n log n) sort works here
// -- the algorithm doesn't depend on which one.
void quicksort(int arr[], int lo, int hi) {
  if (hi - lo <= 1) {
    return;
  }
  int pivot = arr[lo + (hi - lo) / 2];
  std::vector<int> less, equal, greater;

  for (int i = lo; i < hi; i++) {
    if (arr[i] < pivot) {
      less.push_back(arr[i]);
    } else if (arr[i] > pivot) {
      greater.push_back(arr[i]);
    } else {
      equal.push_back(arr[i]);
    }
  }

  quicksort(less.data(), 0, static_cast<int>(less.size()));
  quicksort(greater.data(), 0, static_cast<int>(greater.size()));

  int k = lo;
  for (int value : less) {
    arr[k++] = value;
  }
  for (int value : equal) {
    arr[k++] = value;
  }
  for (int value : greater) {
    arr[k++] = value;
  }
}

void sort(int arr[], int length) {
  if (length < 2) {
    return;
  }

  std::vector<int> dropped;
  int numDroppedInARow = 0;
  int read = 0;
  int write = 0;
  int iteration = 0;
  int earlyOutStop = length / kEarlyOutTestAt;

  while (read < length) {
    iteration++;
    if (iteration == earlyOutStop && static_cast<double>(dropped.size()) >
                                         read * kEarlyOutDisorderFraction) {
      // Too disordered for the adaptive approach to be worth it: flush what's
      // been dropped so far back into the array and fall back to a plain full
      // sort.
      for (int value : dropped) {
        arr[write] = value;
        write++;
      }
      dropped.clear();
      quicksort(arr, 0, length);
      return;
    }

    if (write == 0 || arr[read] >= arr[write - 1]) {
      // In order -- keep it.
      arr[write] = arr[read];
      write++;
      read++;
      numDroppedInARow = 0;
    } else if (numDroppedInARow == 0 && write >= 2 &&
               arr[read] >= arr[write - 2]) {
      // Quick undo: the element two back would have accepted this one just
      // fine, so drop the one right before it instead of the new element.
      dropped.push_back(arr[write - 1]);
      arr[write - 1] = arr[read];
      read++;
    } else if (numDroppedInARow < kRecency) {
      dropped.push_back(arr[read]);
      read++;
      numDroppedInARow++;
    } else {
      // Accepting something `numDroppedInARow` elements back made every
      // subsequent element drop -- that accept was a mistake. Undo it, and any
      // other recently accepted elements bigger than the dropped run's maximum.
      dropped.resize(dropped.size() - numDroppedInARow);
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
        dropped.push_back(arr[i]);
      }

      numDroppedInARow = 0;
    }
  }

  for (size_t offset = 0; offset < dropped.size(); offset++) {
    arr[write + static_cast<int>(offset)] = dropped[offset];
  }

  quicksort(arr, write, length);

  // Copy the now-sorted dropped tail before the final backward merge starts
  // overwriting arr[write:] in place.
  std::vector<int> buffer(arr + write, arr + write + dropped.size());

  int i = static_cast<int>(buffer.size()) - 1;
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
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
