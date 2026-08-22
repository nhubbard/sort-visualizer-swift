#include <algorithm>
#include <cstdio>
#include <utility>
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

// A literal Bogo Bogo Sort re-derives the "is it sorted?" answer through a
// recursive sort of its own, so its real cost grows worse than n! squared --
// even a handful of elements can take an unreasonable amount of time. To keep
// this example runnable, the true recursive algorithm below is only ever
// applied to a small leading slice of the array (kChaosLimit elements); the
// rest is finished with an ordinary insertion sort, and the two already-sorted
// pieces are merged back together at the end. The random reshuffle is also
// replaced with a deterministic, never-repeating permutation walk, so neither
// piece can wander into an unbounded random search.
constexpr int kChaosLimit = 5;

// Advances arr to its next lexicographic permutation in place. Returns false
// (after resetting arr to its first, fully ascending permutation) once every
// arrangement has been visited -- a deterministic stand-in for "shuffle the
// array at random".
bool nextPermutation(std::vector<int> &arr) {
  int n = static_cast<int>(arr.size());
  int i = n - 2;
  while (i >= 0 && arr[i] >= arr[i + 1]) {
    i--;
  }
  if (i < 0) {
    for (int lo = 0, hi = n - 1; lo < hi; lo++, hi--) {
      std::swap(arr[lo], arr[hi]);
    }
    return false;
  }
  int j = n - 1;
  while (arr[j] <= arr[i]) {
    j--;
  }
  std::swap(arr[i], arr[j]);
  for (int lo = i + 1, hi = n - 1; lo < hi; lo++, hi--) {
    std::swap(arr[lo], arr[hi]);
  }
  return true;
}

void bogoBogoSort(std::vector<int> &arr);

// The heart of the joke: rather than scanning arr once, decide whether it is
// sorted by copying it, recursively Bogo-Bogo-sorting the copy's first n - 1
// elements with this exact same process one level down, reshuffling the whole
// copy until its last two elements land in order, and comparing the result
// against the original. A match means the copy is now the true sorted
// arrangement of the same values, which is only possible if arr was already
// sorted.
bool bogoBogoIsSorted(const std::vector<int> &arr) {
  int n = static_cast<int>(arr.size());
  if (n <= 1) {
    return true;
  }
  std::vector<int> copy = arr;
  std::vector<int> prefix(copy.begin(), copy.end() - 1);
  bogoBogoSort(prefix);
  std::copy(prefix.begin(), prefix.end(), copy.begin());
  int candidate = 0;
  while (copy[n - 2] > copy[n - 1]) {
    std::swap(copy[candidate], copy[n - 1]);
    candidate++;
    prefix.assign(copy.begin(), copy.end() - 1);
    bogoBogoSort(prefix);
    std::copy(prefix.begin(), prefix.end(), copy.begin());
  }
  return copy == arr;
}

void bogoBogoSort(std::vector<int> &arr) {
  while (!bogoBogoIsSorted(arr)) {
    nextPermutation(arr);
  }
}

void insertionSort(std::vector<int> &arr) {
  for (std::size_t i = 1; i < arr.size(); i++) {
    int key = arr[i];
    int j = static_cast<int>(i) - 1;
    while (j >= 0 && arr[j] > key) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[j + 1] = key;
  }
}

std::vector<int> mergeSorted(const std::vector<int> &a,
                             const std::vector<int> &b) {
  std::vector<int> merged;
  merged.reserve(a.size() + b.size());
  std::size_t i = 0, j = 0;
  while (i < a.size() && j < b.size()) {
    if (a[i] <= b[j]) {
      merged.push_back(a[i++]);
    } else {
      merged.push_back(b[j++]);
    }
  }
  while (i < a.size()) {
    merged.push_back(a[i++]);
  }
  while (j < b.size()) {
    merged.push_back(b[j++]);
  }
  return merged;
}

void sort(int arr[], int n) {
  int limit = n < kChaosLimit ? n : kChaosLimit;
  std::vector<int> chaos(arr, arr + limit);
  std::vector<int> rest(arr + limit, arr + n);

  bogoBogoSort(
      chaos); // the real, recursive-check algorithm -- kept tiny on purpose
  insertionSort(rest); // an ordinary fast sort for the rest of the array

  std::vector<int> merged = mergeSorted(chaos, rest);
  for (int k = 0; k < n; k++) {
    arr[k] = merged[k];
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
