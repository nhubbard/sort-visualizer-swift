#include <algorithm>
#include <cstdio>
#include <unordered_map>
#include <vector>

int array[24] = {34, 7,  23, 90, 12, 56, 3,  45, 78, 21, 66, 9,
                 50, 15, 88, 40, 61, 5,  33, 72, 18, 95, 27, 60};

// Tags a value with its original index so a pending element can find its way
// back to the right chain partner even after the chain has been recursively
// reordered.
struct Elem {
  int value;
  int index;
};

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

// Inserts elem into the already-sorted seq via binary search, comparing by
// value only.
void binaryInsert(std::vector<Elem> &seq, Elem elem) {
  int lo = 0;
  int hi = static_cast<int>(seq.size());
  while (lo < hi) {
    int mid = (lo + hi) / 2;
    if (seq[mid].value <= elem.value) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  seq.insert(seq.begin() + lo, elem);
}

// Returns, as 1-based positions into a list of `count` not-yet-placed
// pending elements, the order to insert them in: 2, then 4 and 3, then 10
// down to 5, then 20 down to 11, and so on. This Jacobsthal-number grouping
// is what makes merge-insertion sort comparison-optimal. Position 1 is
// never included -- it is always placed for free before any of these
// insertions happen.
std::vector<int> jacobsthalInsertionOrder(int count) {
  int maxPosition = count + 1;
  std::vector<int> order;
  int placedThrough = 1;
  int k = 2;
  while (placedThrough < maxPosition) {
    int sign = (k % 2 == 0) ? 1 : -1;
    int t = ((1 << (k + 1)) + sign) / 3;
    int groupEnd = std::min(t - 1, maxPosition);
    for (int position = groupEnd; position > placedThrough; position--) {
      order.push_back(position);
    }
    placedThrough = groupEnd;
    k++;
  }
  return order;
}

// Splits items into chain (the larger element of each adjacent pair),
// partnerOf (mapping a chain element's original index to its paired,
// smaller element), and extra (a leftover element with no partner when
// items has odd length; hasExtra reports whether it is present).
void pairUp(const std::vector<Elem> &items, std::vector<Elem> &chain,
            std::unordered_map<int, Elem> &partnerOf, Elem &extra,
            bool &hasExtra) {
  size_t i = 0;
  size_t n = items.size();
  while (i + 1 < n) {
    Elem a = items[i], b = items[i + 1];
    Elem small = (a.value <= b.value) ? a : b;
    Elem large = (a.value <= b.value) ? b : a;
    partnerOf[large.index] = small;
    chain.push_back(large);
    i += 2;
  }
  if (i < n) {
    extra = items[i];
    hasExtra = true;
  } else {
    hasExtra = false;
  }
}

// Sorts a list of Elem by value, following merge-insertion sort. The index
// tags are what let a pending element find its way back to the right chain
// partner after the chain has been recursively reordered by this same
// function one level down.
std::vector<Elem> sortTagged(const std::vector<Elem> &items) {
  if (items.size() <= 1) {
    return items;
  }

  std::vector<Elem> chain;
  std::unordered_map<int, Elem> partnerOf;
  Elem extra{};
  bool hasExtra = false;
  pairUp(items, chain, partnerOf, extra, hasExtra);

  std::vector<Elem> sortedChain = sortTagged(chain);

  // The pending partner of the smallest chain element is guaranteed smaller
  // than every other chain element too, so it can go straight to the front
  // with no comparison at all.
  std::vector<Elem> sequence;
  sequence.push_back(partnerOf[sortedChain[0].index]);
  sequence.insert(sequence.end(), sortedChain.begin(), sortedChain.end());

  std::vector<Elem> remaining;
  for (size_t k = 1; k < sortedChain.size(); k++) {
    remaining.push_back(partnerOf[sortedChain[k].index]);
  }
  if (hasExtra) {
    remaining.push_back(extra);
  }

  for (int position :
       jacobsthalInsertionOrder(static_cast<int>(remaining.size()))) {
    binaryInsert(sequence, remaining[position - 2]);
  }

  return sequence;
}

void sort(int arr[], int n) {
  if (n < 2) {
    return;
  }
  std::vector<Elem> tagged;
  tagged.reserve(n);
  for (int i = 0; i < n; i++) {
    tagged.push_back({arr[i], i});
  }
  std::vector<Elem> sortedTagged = sortTagged(tagged);
  for (int i = 0; i < n; i++) {
    arr[i] = sortedTagged[i].value;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
