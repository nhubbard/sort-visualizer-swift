#include <cstdio>
#include <algorithm>
#include <cstdint>
#include <iostream>
#include <vector>
using namespace std;

void printList(const std::vector<int> &items) {
  printf("[");
  if (!items.empty()) {
    printf("%d", items[0]);
    for (size_t i = 1; i < items.size(); i++) {
      printf(", %d", items[i]);
    }
  }
  printf("]\n");
}

static void flanSort(vector<int> &values);

void sort(vector<int> &values) {
  flanSort(values);
}

class Flan {
  static constexpr int gap = 14, ratio = 4;
  vector<int> &a;
  int position[gap + 2] = {}, heap[gap + 2] = {};
  uint64_t state = 0x9e3779b97f4a7c15ULL;
  void exchange(int i, int j) { swap(a[i], a[j]); }
  int choice(int count) {
    state ^= state >> 12;
    state ^= state << 25;
    state ^= state >> 27;
    return (state * 0x2545f4914f6cdd1dULL) % count;
  }
  int median(int i, int m, int j) {
    if (a[m] > a[i]) {
      if (a[m] < a[j])
        return m;
      return a[i] > a[j] ? i : j;
    }
    if (a[m] > a[j])
      return m;
    return a[i] < a[j] ? i : j;
  }
  int ninther(int first, int last) {
    int step = (last - first) / 9;
    return median(median(first, first + step, first + 2 * step),
                  median(first + 3 * step, first + 4 * step, first + 5 * step),
                  median(first + 6 * step, first + 7 * step, first + 8 * step));
  }
  int pivot(int first, int last) {
    int step = (last - first) / 3;
    return median(ninther(first, first + step),
                  ninther(first + step, first + 2 * step),
                  ninther(first + 2 * step, last));
  }
  int binarySearch(int first, int last, int value, bool backward) {
    while (first < last) {
      int middle = first + (last - first) / 2;
      bool found = backward ? a[middle] < value : a[middle] > value;
      if (found)
        last = middle;
      else
        first = middle + 1;
    }
    return first;
  }
  void insert(int value, int from, int to) {
    while (from > to) {
      --from;
      a[from + 1] = a[from];
    }
    a[to] = value;
  }
  void insertion(int first, int last) {
    for (int i = first + 1; i < last; ++i) {
      int value = a[i];
      insert(value, i, binarySearch(first, i, value, false));
    }
  }
  int blockSearch(int first, int last, int value, bool right) {
    while (first < last) {
      int middle = first + ((last - first) / (gap + 1) / 2) * (gap + 1);
      bool found = right ? a[middle] > value : a[middle] >= value;
      if (found)
        last = middle;
      else
        first = middle + gap + 1;
    }
    return first;
  }
  void retrieve(int finish, int scratch, int pEnd, int boundary,
                bool backward) {
    int destination = finish - 1, block = pEnd - (gap + 1);
    while (block > scratch + gap) {
      int item = binarySearch(block - gap, block, boundary, backward) - 1;
      block -= gap + 1;
      while (item >= block) {
        exchange(destination, item);
        --destination;
        --item;
      }
    }
    int item = binarySearch(scratch, scratch + gap, boundary, backward) - 1;
    while (item >= scratch) {
      exchange(destination, item);
      --destination;
      --item;
    }
  }
  void librarySort(int first, int last, int scratch, int boundary,
                   bool backward) {
    int length = last - first;
    if (length < 32) {
      insertion(first, last);
      return;
    }
    int count = length;
    while (count >= 32)
      count = (count - 1) / ratio + 1;
    int i = first + count, trigger = first + ratio * count,
        pEnd = scratch + (count + 1) * (gap + 1) + gap;
    insertion(first, i);
    for (int k = 0; k < count; ++k)
      exchange(first + k, scratch + k * (gap + 1) + gap);
    while (i < last) {
      if (i == trigger) {
        retrieve(i, scratch, pEnd, boundary, backward);
        count = i - first;
        pEnd = scratch + (count + 1) * (gap + 1) + gap;
        trigger = first + (trigger - first) * ratio;
        for (int k = 0; k < count; ++k)
          exchange(first + k, scratch + k * (gap + 1) + gap);
      }
      int value = a[i];
      int block = blockSearch(scratch + gap, pEnd - (gap + 1), value, false);
      if (a[block] == value) {
        int afterEqual =
            blockSearch(block + gap + 1, pEnd - (gap + 1), value, true);
        block += choice((afterEqual - block) / (gap + 1)) * (gap + 1);
      }
      int loc = binarySearch(block - gap, block, boundary, backward);
      if (loc == block) {
        do {
          block += gap + 1;
        } while (block < pEnd &&
                 binarySearch(block - gap, block, boundary, backward) == block);
        if (block == pEnd) {
          retrieve(i, scratch, pEnd, boundary, backward);
          count = i - first;
          pEnd = scratch + (count + 1) * (gap + 1) + gap;
          trigger = first + (trigger - first) * ratio;
          for (int k = 0; k < count; ++k)
            exchange(first + k, scratch + k * (gap + 1) + gap);
        } else {
          int firstItem = binarySearch(block - gap, block, boundary, backward);
          int distance = block - max(firstItem, block - gap / 2);
          int source = block - distance, destination = block;
          while (source > loc - distance) {
            --source;
            --destination;
            exchange(destination, source);
          }
        }
      } else {
        int displaced = a[loc];
        a[i] = displaced;
        ++i;
        insert(value, loc, binarySearch(block - gap, loc, value, false));
      }
    }
    retrieve(last, scratch, pEnd, boundary, backward);
  }
  bool less(int x, int y) {
    int left = a[position[x]], right = a[position[y]];
    return left < right || (left == right && x < y);
  }
  void sift(int item, int first, int size) {
    int root = first;
    while (2 * root + 2 < size) {
      int left = 2 * root + 1,
          child = less(heap[left], heap[left + 1]) ? left : left + 1;
      if (!less(heap[child], item))
        break;
      heap[root] = heap[child];
      root = child;
    }
    int left = 2 * root + 1;
    if (left < size && less(heap[left], item)) {
      heap[root] = heap[left];
      root = left;
    }
    heap[root] = item;
  }
  void merge(int runLength, int finish, int destination, int count) {
    if (count < 2) {
      if (count == 1)
        while (position[0] < finish) {
          exchange(destination, position[0]);
          ++destination;
          ++position[0];
        }
      return;
    }
    int first = position[0];
    for (int i = 0; i < count; ++i)
      heap[i] = i;
    for (int i = (count - 1) / 2; i >= 0; --i)
      sift(heap[i], i, count);
    int size = count;
    while (size > 0) {
      int run = heap[0];
      exchange(destination, position[run]);
      ++destination;
      ++position[run];
      if (position[run] == min(first + (run + 1) * runLength, finish)) {
        --size;
        sift(heap[size], 0, size);
      } else
        sift(heap[0], 0, size);
    }
  }

public:
  explicit Flan(vector<int> &values) : a(values) {
    for (int value : a)
      state = (state ^ static_cast<uint64_t>(static_cast<int64_t>(value))) *
                  0xbf58476d1ce4e5b9ULL +
              0x94d049bb133111ebULL;
  }
  void execute() {
    int first = 0, finish = (int)a.size();
    while (finish - first >= 32) {
      int value = a[pivot(first, finish)];
      int before = first, i = first - 1, j = finish, after = finish;
      while (true) {
        ++i;
        while (i < j) {
          if (a[i] == value) {
            exchange(before, i);
            ++before;
          } else if (a[i] < value)
            break;
          ++i;
        }
        --j;
        while (j > i) {
          if (a[j] == value) {
            --after;
            exchange(after, j);
          } else if (a[j] > value)
            break;
          --j;
        }
        if (i < j)
          exchange(i, j);
        else {
          if (before == finish)
            return;
          if (j < i)
            ++j;
          while (before > first) {
            --i;
            --before;
            exchange(i, before);
          }
          while (after < finish) {
            exchange(j, after);
            ++j;
            ++after;
          }
          break;
        }
      }
      int left = i - first, right = finish - j, count = 0;
      if (left <= right) {
        int move = finish - left;
        left = max((right + 1) / (gap + 1), 16);
        for (int k = first; k < i; k += left) {
          librarySort(k, min(k + left, i), j, value, true);
          position[count++] = k;
        }
        merge(left, i, move, count);
        if (j - i < move - j) {
          while (i < j) {
            --move;
            exchange(i, move);
            ++i;
          }
          finish = move;
        } else {
          while (move > j) {
            --move;
            exchange(i, move);
            ++i;
          }
          finish = i;
        }
      } else {
        int move = first + right;
        right = max((left + 1) / (gap + 1), 16);
        for (int k = j; k < finish; k += right) {
          librarySort(k, min(k + right, finish), first, value, false);
          position[count++] = k;
        }
        merge(right, finish, first, count);
        if (i - move < j - i) {
          while (move < i) {
            --j;
            exchange(move, j);
            ++move;
          }
          first = j;
        } else {
          while (j > i) {
            --j;
            exchange(move, j);
            ++move;
          }
          first = move;
        }
      }
    }
    insertion(first, finish);
  }
};


static void flanSort(vector<int> &values) {
  if (values.size() > 1)
    Flan(values).execute();
}
int main() {
  vector<int> a = {0,  39, 21, 62, 91, 77, 14, 23,
                   90, 69, 51, 81, 68, 83, 32, 56};
  sort(a);
  printList(a);
}
