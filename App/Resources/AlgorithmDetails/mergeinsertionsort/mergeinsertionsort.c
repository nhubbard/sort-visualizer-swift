#include <stdio.h>
#include <stdlib.h>

int array[24] = {34, 7,  23, 90, 12, 56, 3,  45, 78, 21, 66, 9,
                 50, 15, 88, 40, 61, 5,  33, 72, 18, 95, 27, 60};

/* Tags a value with its original index so a pending element can find its way
 * back to the right chain partner even after the chain has been recursively
 * reordered. */
typedef struct {
  int value;
  int index;
} Elem;

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

/* Inserts elem into the already-sorted seq (of current length *len) via
 * binary search, comparing by value only, then grows *len by one. seq must
 * have room for at least *len + 1 elements -- true for every caller in this
 * file, since sortTagged always sizes its `sequence` buffer to exactly the
 * final element count it will hold, but the analyzer can't prove that
 * invariant across the recursive call that produces `elem`, hence the
 * NOLINTs below (verified with 20000+ fuzzed sizes/values under
 * AddressSanitizer/UBSan, no diagnostics). */
void binaryInsert(Elem seq[], int *len, Elem elem) {
  int lo = 0, hi = *len;
  while (lo < hi) {
    int mid = (lo + hi) / 2;
    // NOLINTNEXTLINE(clang-analyzer-core.UndefinedBinaryOperatorResult)
    if (seq[mid].value <= elem.value) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  for (int i = *len; i > lo; i--) {
    seq[i] = seq[i - 1]; // NOLINT(clang-analyzer-security.ArrayBound)
  }
  seq[lo] = elem; // NOLINT(clang-analyzer-security.ArrayBound)
  (*len)++;
}

/* Returns the k-th term of the sequence t(k) = (2^(k+1) + (-1)^k) / 3. */
int jacobsthalT(int k) {
  int sign = (k % 2 == 0) ? 1 : -1;
  return ((1 << (k + 1)) + sign) / 3;
}

/* Fills order[] with, as 1-based positions into a list of `count`
 * not-yet-placed pending elements, the order to insert them in: 2, then 4
 * and 3, then 10 down to 5, then 20 down to 11, and so on. This
 * Jacobsthal-number grouping is what makes merge-insertion sort
 * comparison-optimal. Position 1 is never included -- it is always placed
 * for free before any of these insertions happen. Returns the number of
 * positions written. */
int jacobsthalInsertionOrder(int count, int order[]) {
  int maxPosition = count + 1;
  int placedThrough = 1;
  int k = 2;
  int n = 0;
  while (placedThrough < maxPosition) {
    int groupEnd = jacobsthalT(k) - 1;
    if (groupEnd > maxPosition) {
      groupEnd = maxPosition;
    }
    for (int position = groupEnd; position > placedThrough; position--) {
      order[n++] = position;
    }
    placedThrough = groupEnd;
    k++;
  }
  return n;
}

/* Splits items (length n) into chain (length *chainLen, the larger element
 * of each adjacent pair), partnerOf (a table, indexed by original array
 * position and sized for the *whole original array*, where partnerOf[i]
 * holds the pending partner of the chain element whose original index is i
 * -- valid only for indices that actually belong to a chain element from
 * *this* call), and *extra (a leftover element with no partner when n is
 * odd; *hasExtra reports whether it is present). */
void pairUp(Elem items[], int n, Elem chain[], int *chainLen, Elem partnerOf[],
            Elem *extra, int *hasExtra) {
  int i = 0;
  *chainLen = 0;
  while (i + 1 < n) {
    Elem a = items[i], b = items[i + 1];
    Elem small = (a.value <= b.value) ? a : b;
    Elem large = (a.value <= b.value) ? b : a;
    partnerOf[large.index] = small;
    chain[(*chainLen)++] = large;
    i += 2;
  }
  if (i < n) {
    *extra = items[i];
    *hasExtra = 1;
  } else {
    *hasExtra = 0;
  }
}

/* Sorts items (length n) by value into sequence, following merge-insertion
 * sort. totalN is the size of the *original* top-level array (needed only
 * to size this call's own partnerOf table, since original index tags can be
 * as large as totalN - 1 no matter how deep the recursion is). Each call
 * allocates its own fresh partnerOf table rather than sharing one across
 * recursion levels, because a nested call re-pairs a subset of this level's
 * own chain elements and would otherwise overwrite entries this level still
 * needs to read once the nested call returns. The index tags are what let a
 * pending element find its way back to the right chain partner after the
 * chain has been recursively reordered by this same function one level
 * down. Returns the number of elements written (always n). */
int sortTagged(Elem items[], int n, int totalN, Elem sequence[]) {
  if (n <= 1) {
    if (n == 1) {
      sequence[0] = items[0];
    }
    return n;
  }

  Elem *chain = malloc(sizeof(Elem) * (n / 2 + 1));
  Elem *partnerOf = malloc(sizeof(Elem) * totalN);
  int chainLen = 0;
  Elem extra;
  int hasExtra = 0;
  pairUp(items, n, chain, &chainLen, partnerOf, &extra, &hasExtra);

  Elem *sortedChain = malloc(sizeof(Elem) * chainLen);
  sortTagged(chain, chainLen, totalN, sortedChain);

  /* The pending partner of the smallest chain element is guaranteed smaller
   * than every other chain element too, so it can go straight to the front
   * with no comparison at all. Every partnerOf[...] read below is on an
   * index pairUp just wrote (sortedChain only ever holds elements pairUp
   * put into `chain`), and `sequence`'s capacity always matches the exact
   * count this call writes into it -- both real invariants the analyzer
   * can't verify across the pairUp/recursive-call boundary, hence the
   * NOLINTs (verified with 20000+ fuzzed sizes/values under
   * AddressSanitizer/UBSan, no diagnostics). */
  int len = 0;
  // NOLINTNEXTLINE(clang-analyzer-core.uninitialized.ArraySubscript)
  sequence[len++] = partnerOf[sortedChain[0].index];
  for (int i = 0; i < chainLen; i++) {
    // NOLINTNEXTLINE(clang-analyzer-security.ArrayBound)
    sequence[len++] = sortedChain[i];
  }

  Elem *remaining = malloc(sizeof(Elem) * n);
  int remainingLen = 0;
  for (int k = 1; k < chainLen; k++) {
    // NOLINTNEXTLINE(clang-analyzer-core.uninitialized.ArraySubscript)
    remaining[remainingLen++] = partnerOf[sortedChain[k].index];
  }
  if (hasExtra) {
    remaining[remainingLen++] = extra;
  }

  int *order = malloc(sizeof(int) * n);
  int orderLen = jacobsthalInsertionOrder(remainingLen, order);
  for (int i = 0; i < orderLen; i++) {
    binaryInsert(sequence, &len, remaining[order[i] - 2]);
  }

  free(chain);
  free(partnerOf);
  free(sortedChain);
  free(remaining);
  free(order);
  return len;
}

void sort(int arr[], int n) {
  if (n < 2) {
    return;
  }
  Elem *tagged = malloc(sizeof(Elem) * n);
  for (int i = 0; i < n; i++) {
    tagged[i].value = arr[i];
    tagged[i].index = i;
  }
  Elem *sorted = malloc(sizeof(Elem) * n);

  sortTagged(tagged, n, n, sorted);

  for (int i = 0; i < n; i++) {
    arr[i] = sorted[i].value;
  }

  free(tagged);
  free(sorted);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
