#include <cstdio>
#include <utility>

class CircularGrailSort {
public:
  void sort(int array[], int size) {
    items = array;
    count = size;
    if (count < 2)
      return;
    if (count <= 16) {
      insertion(0, count);
      return;
    }
    int block = 1;
    while (block * block < count)
      block *= 2;
    int i = block;
    int run = 1;
    const int rolling = count - block;
    int end = count;
    while (run <= block) {
      while (i + 2 * run < end) {
        merge(i - run, i, i + run, i + 2 * run, true);
        i += 2 * run;
      }
      if (i + run < end)
        merge(i - run, i, i + run, end, true);
      else
        shiftForward(i - run, i, end);
      i = end + block - run;
      end = i + rolling;
      run *= 2;
    }
    while (run < rolling) {
      while (i + 2 * run < end) {
        blockMerge(i, i + run, i + 2 * run, block);
        i += 2 * run;
      }
      if (i + run < end)
        blockMerge(i, i + run, end, block);
      else
        shiftForward(i - block, i, end);
      i = end;
      end += rolling;
      run *= 2;
    }
    insertion(i - block, i);
    inPlaceMerge(i - block, i, end);
    rotate(0, (i - block) % count, count);
  }

private:
  int *items = nullptr;
  int count = 0;

  void circularSwap(int a, int b) {
    std::swap(items[a % count], items[b % count]);
  }
  void shiftForward(int a, int middle, int end) {
    while (middle < end)
      circularSwap(a++, middle++);
  }
  void shiftBackward(int start, int middle, int end) {
    while (middle > start)
      circularSwap(--end, --middle);
  }
  void insertion(int start, int end) {
    for (int first = start + 1; first < end; first++) {
      int i = first;
      while (i > start && items[(i - 1) % count] > items[i % count]) {
        i--;
        circularSwap(i + 1, i);
      }
    }
  }
  void multiSwap(int a, int b, int length) {
    for (int i = 0; i < length; i++)
      circularSwap(a + i, b + i);
  }
  void rotate(int start, int middle, int end) {
    int left = middle - start;
    int right = end - middle;
    while (left > 0 && right > 0) {
      if (right < left) {
        multiSwap(middle - right, middle, right);
        end -= right;
        middle -= right;
        left -= right;
      } else {
        multiSwap(start, middle, left);
        start += left;
        middle += left;
        right -= left;
      }
    }
  }
  void inPlaceMerge(int start, int middle, int end) {
    int i = start;
    while (i < middle && middle < end) {
      if (items[i % count] > items[middle % count]) {
        int k = middle + 1;
        while (k < end && items[i % count] > items[k % count])
          k++;
        rotate(i, middle, k);
        i += k - middle;
        middle = k;
      } else
        i++;
    }
  }
  int merge(int p, int start, int middle, int end, bool full) {
    int i = start;
    int j = middle;
    while (i < middle && j < end) {
      if (items[i % count] <= items[j % count])
        circularSwap(p++, i++);
      else
        circularSwap(p++, j++);
    }
    if (i < middle) {
      if (i > p)
        shiftForward(p, i, middle);
    } else if (full)
      shiftForward(p, j, end);
    return i < middle ? i : j;
  }
  bool blockLess(int a, int b, int length) const {
    if (items[a % count] != items[b % count])
      return items[a % count] < items[b % count];
    return items[(a + length - 1) % count] < items[(b + length - 1) % count];
  }
  void blockMerge(int start, int middle, int end, int length) {
    const int b1 = end - (end - middle - 1) % length - 1;
    if (b1 <= middle) {
      merge(start - length, start, middle, end, true);
      return;
    }
    int b2 = b1;
    for (int i = middle - length; i > start && blockLess(b1, i, length);
         i -= length)
      b2 -= length;
    for (int j = start; j < b1 - length; j += length) {
      int minimum = j;
      for (int i = j + length; i < b1; i += length)
        if (blockLess(i, minimum, length))
          minimum = i;
      if (minimum != j)
        multiSwap(j, minimum, length);
    }
    int frontier = start;
    for (int i = start + length; i < b2; i += length) {
      frontier = merge(frontier - length, frontier, i, i + length, false);
      if (frontier < i) {
        shiftBackward(frontier, i, i + length);
        frontier += length;
      }
    }
    merge(frontier - length, frontier, b1, end, true);
  }
};

int main() {
  int array[] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
  const int size = static_cast<int>(sizeof(array) / sizeof(array[0]));
  CircularGrailSort().sort(array, size);
  std::printf("[");
  for (int i = 0; i < size; i++)
    std::printf(i == 0 ? "%d" : ", %d", array[i]);
  std::printf("]");
}
