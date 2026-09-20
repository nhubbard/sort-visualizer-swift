#include <algorithm>
#include <iostream>
#include <vector>
using namespace std;

void sort(vector<int> &a) {
  const int n = (int)a.size();
  if (n < 2)
    return;
  int lo = 0, hi = min(n, 1291);
  while (lo < hi) {
    int mid = (lo + hi) / 2;
    if (mid * mid * mid >= n)
      hi = mid;
    else
      lo = mid + 1;
  }
  const int block = lo, runLength = block * block,
            runs = (n - 1) / runLength + 1;
  vector<int> keys(runs < 2 ? n : runLength);
  for (int i = 0; i < (int)keys.size(); ++i)
    keys[i] = i;
  auto greater = [&](int x, int y, int base) {
    int vx = a[base + x], vy = a[base + y];
    return vx > vy || (vx == vy && x > y);
  };
  auto tableSift = [&](int root, int length, int base, int item) {
    int j = root;
    while (2 * j + 1 < length) {
      j = 2 * j + 1;
      if (j + 1 < length && greater(keys[j + 1], keys[j], base))
        ++j;
    }
    while (j > root && greater(item, keys[j], base))
      j = (j - 1) / 2;
    while (j > root) {
      swap(item, keys[j]);
      j = (j - 1) / 2;
    }
    keys[root] = item;
  };
  auto tableSort = [&](int start, int end) {
    int length = end - start;
    if (length < 2)
      return;
    for (int i = (length - 1) / 2; i >= 0; --i)
      tableSift(i, length, start, keys[i]);
    for (int i = length - 1; i > 0; --i) {
      int item = keys[i];
      keys[i] = keys[0];
      tableSift(0, i, start, item);
    }
    for (int i = 0; i < length; ++i) {
      if (keys[i] == i)
        continue;
      int held = a[start + i], j = i, next = keys[i];
      do {
        a[start + j] = a[start + next];
        keys[j] = j;
        j = next;
        next = keys[next];
      } while (next != i);
      a[start + j] = held;
      keys[j] = j;
    }
  };
  if (runs < 2) {
    tableSort(0, n);
    return;
  }
  vector<int> buffer(runLength), heap(runs), position(runs), destination(runs);
  for (int r = 0; r < runs; ++r) {
    int start = r * runLength;
    tableSort(start, min(start + runLength, n));
    heap[r] = r;
    position[r] = destination[r] = start;
  }
  auto less = [&](int x, int y) {
    int vx = a[position[x]], vy = a[position[y]];
    return vx < vy || (vx == vy && x < y);
  };
  auto sift = [&](int item, int root, int size) {
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
  };
  for (int i = (runs - 1) / 2; i >= 0; --i)
    sift(heap[i], i, runs);
  int size = runs;
  auto advance = [&](int r) {
    ++position[r];
    if (position[r] == min((r + 1) * runLength, n)) {
      --size;
      sift(heap[size], 0, size);
    } else
      sift(heap[0], 0, size);
  };
  for (int i = 0; i < runLength; ++i) {
    int r = heap[0];
    buffer[i] = a[position[r]];
    advance(r);
  }
  int t = 0, count = 0, cursor = 0;
  while (position[cursor] - destination[cursor] < block)
    ++cursor;
  do {
    int r = heap[0];
    a[destination[cursor]++] = a[position[r]];
    advance(r);
    ++count;
    if (count == block) {
      keys[t++] = cursor > 0 ? destination[cursor] / block - block - 1 : -1;
      cursor = 0;
      count = 0;
      while (position[cursor] - destination[cursor] < block)
        ++cursor;
    }
  } while (size > 0);
  int end = n;
  while (count > 0) {
    --count;
    --destination[cursor];
    a[--end] = a[destination[cursor]];
  }
  position[runs - 1] = end;
  keys.back() = -1;
  t = 0;
  while (keys[t] != -1)
    ++t;
  int source = 0;
  for (int r = 1; r < runs && source < destination[0]; ++r) {
    while (destination[r] < position[r]) {
      keys[t++] = destination[r] / block - block;
      while (keys[t] != -1)
        ++t;
      for (int x = 0; x < block; ++x)
        a[destination[r] + x] = a[source + x];
      destination[r] += block;
      source += block;
    }
  }
  copy(buffer.begin(), buffer.end(), a.begin());
  const int blocks = (end - runLength) / block;
  for (int i = 0; i < blocks; ++i) {
    if (keys[i] == i)
      continue;
    copy_n(a.begin() + runLength + i * block, block, buffer.begin());
    int j = i, next = keys[i];
    do {
      copy_n(a.begin() + runLength + next * block, block,
             a.begin() + runLength + j * block);
      keys[j] = j;
      j = next;
      next = keys[next];
    } while (next != i);
    copy_n(buffer.begin(), block, a.begin() + runLength + j * block);
    keys[j] = j;
  }
}
int main() {
  vector<int> a = {0,  39, 21, 62, 91, 77, 14, 23,
                   90, 69, 51, 81, 68, 83, 32, 56};
  sort(a);
  cout << "[";
  for (size_t i = 0; i < a.size(); ++i) {
    if (i)
      cout << ", ";
    cout << a[i];
  }
  cout << "]\n";
}
