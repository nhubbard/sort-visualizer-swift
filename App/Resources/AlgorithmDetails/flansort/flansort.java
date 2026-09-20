import java.util.Arrays;

public class flansort {
  private static final int GAP = 14, RATIO = 4;
  private final int[] values;
  private final int[] positions = new int[GAP + 2], heap = new int[GAP + 2];
  private long state = 0x9e3779b97f4a7c15L;

  private flansort(int[] array) {
    values = array;
    for (int value : values)
      state = (state ^ (long) value) * 0xbf58476d1ce4e5b9L + 0x94d049bb133111ebL;
  }

  private int choice(int count) {
    state ^= state >>> 12;
    state ^= state << 25;
    state ^= state >>> 27;
    return (int) Long.remainderUnsigned(state * 0x2545f4914f6cdd1dL, count);
  }

  private void swap(int i, int j) {
    int item = values[i];
    values[i] = values[j];
    values[j] = item;
  }

  private int median(int a, int m, int b) {
    if (values[m] > values[a]) {
      if (values[m] < values[b]) return m;
      return values[a] > values[b] ? a : b;
    }
    if (values[m] > values[b]) return m;
    return values[a] < values[b] ? a : b;
  }

  private int ninther(int a, int b) {
    int step = (b - a) / 9;
    return median(
        median(a, a + step, a + 2 * step),
        median(a + 3 * step, a + 4 * step, a + 5 * step),
        median(a + 6 * step, a + 7 * step, a + 8 * step));
  }

  private int pivot(int a, int b) {
    int step = (b - a) / 3;
    return median(ninther(a, a + step), ninther(a + step, a + 2 * step), ninther(a + 2 * step, b));
  }

  private int binarySearch(int a, int b, int value, boolean backward) {
    while (a < b) {
      int middle = a + (b - a) / 2;
      boolean found = backward ? values[middle] < value : values[middle] > value;
      if (found) b = middle;
      else a = middle + 1;
    }
    return a;
  }

  private void insert(int value, int from, int to) {
    while (from > to) {
      from--;
      values[from + 1] = values[from];
    }
    values[to] = value;
  }

  private void insertion(int a, int b) {
    for (int i = a + 1; i < b; i++) {
      int value = values[i];
      insert(value, i, binarySearch(a, i, value, false));
    }
  }

  private int blockSearch(int a, int b, int value, boolean right) {
    while (a < b) {
      int middle = a + ((b - a) / (GAP + 1) / 2) * (GAP + 1);
      boolean found = right ? values[middle] > value : values[middle] >= value;
      if (found) b = middle;
      else a = middle + GAP + 1;
    }
    return a;
  }

  private void retrieve(int end, int scratch, int pEnd, int boundary, boolean backward) {
    int destination = end - 1, block = pEnd - (GAP + 1);
    while (block > scratch + GAP) {
      int item = binarySearch(block - GAP, block, boundary, backward) - 1;
      block -= GAP + 1;
      while (item >= block) {
        swap(destination, item);
        destination--;
        item--;
      }
    }
    int item = binarySearch(scratch, scratch + GAP, boundary, backward) - 1;
    while (item >= scratch) {
      swap(destination, item);
      destination--;
      item--;
    }
  }

  private void librarySort(int a, int b, int scratch, int boundary, boolean backward) {
    int length = b - a;
    if (length < 32) {
      insertion(a, b);
      return;
    }
    int count = length;
    while (count >= 32) count = (count - 1) / RATIO + 1;
    int i = a + count, trigger = a + RATIO * count;
    int pEnd = scratch + (count + 1) * (GAP + 1) + GAP;
    insertion(a, i);
    for (int k = 0; k < count; k++) swap(a + k, scratch + k * (GAP + 1) + GAP);
    while (i < b) {
      if (i == trigger) {
        retrieve(i, scratch, pEnd, boundary, backward);
        count = i - a;
        pEnd = scratch + (count + 1) * (GAP + 1) + GAP;
        trigger = a + (trigger - a) * RATIO;
        for (int k = 0; k < count; k++) swap(a + k, scratch + k * (GAP + 1) + GAP);
      }
      int value = values[i];
      int block = blockSearch(scratch + GAP, pEnd - (GAP + 1), value, false);
      if (values[block] == value) {
        int afterEqual = blockSearch(block + GAP + 1, pEnd - (GAP + 1), value, true);
        block += choice((afterEqual - block) / (GAP + 1)) * (GAP + 1);
      }
      int loc = binarySearch(block - GAP, block, boundary, backward);
      if (loc == block) {
        do {
          block += GAP + 1;
        } while (block < pEnd && binarySearch(block - GAP, block, boundary, backward) == block);
        if (block == pEnd) {
          retrieve(i, scratch, pEnd, boundary, backward);
          count = i - a;
          pEnd = scratch + (count + 1) * (GAP + 1) + GAP;
          trigger = a + (trigger - a) * RATIO;
          for (int k = 0; k < count; k++) swap(a + k, scratch + k * (GAP + 1) + GAP);
        } else {
          int first = binarySearch(block - GAP, block, boundary, backward);
          int distance = block - Math.max(first, block - GAP / 2);
          int source = block - distance, destination = block;
          while (source > loc - distance) {
            source--;
            destination--;
            swap(destination, source);
          }
        }
      } else {
        int displaced = values[loc];
        values[i] = displaced;
        i++;
        insert(value, loc, binarySearch(block - GAP, loc, value, false));
      }
    }
    retrieve(b, scratch, pEnd, boundary, backward);
  }

  private boolean less(int x, int y) {
    int left = values[positions[x]], right = values[positions[y]];
    return left < right || (left == right && x < y);
  }

  private void sift(int item, int start, int size) {
    int root = start;
    while (2 * root + 2 < size) {
      int left = 2 * root + 1;
      int child = less(heap[left], heap[left + 1]) ? left : left + 1;
      if (!less(heap[child], item)) break;
      heap[root] = heap[child];
      root = child;
    }
    int last = 2 * root + 1;
    if (last < size && less(heap[last], item)) {
      heap[root] = heap[last];
      root = last;
    }
    heap[root] = item;
  }

  private void merge(int runLength, int end, int destination, int count) {
    if (count < 2) {
      if (count == 1)
        while (positions[0] < end) {
          swap(destination, positions[0]);
          destination++;
          positions[0]++;
        }
      return;
    }
    int start = positions[0];
    for (int i = 0; i < count; i++) heap[i] = i;
    for (int i = (count - 1) / 2; i >= 0; i--) sift(heap[i], i, count);
    int size = count;
    while (size > 0) {
      int run = heap[0];
      swap(destination, positions[run]);
      destination++;
      positions[run]++;
      if (positions[run] == Math.min(start + (run + 1) * runLength, end)) {
        size--;
        sift(heap[size], 0, size);
      } else sift(heap[0], 0, size);
    }
  }

  private void execute() {
    int a = 0, b = values.length;
    while (b - a >= 32) {
      int pivot = values[pivot(a, b)];
      int first = a, i = a - 1, j = b, last = b;
      while (true) {
        i++;
        while (i < j) {
          if (values[i] == pivot) {
            swap(first, i);
            first++;
          } else if (values[i] < pivot) break;
          i++;
        }
        j--;
        while (j > i) {
          if (values[j] == pivot) {
            last--;
            swap(last, j);
          } else if (values[j] > pivot) break;
          j--;
        }
        if (i < j) swap(i, j);
        else {
          if (first == b) return;
          if (j < i) j++;
          while (first > a) {
            i--;
            first--;
            swap(i, first);
          }
          while (last < b) {
            swap(j, last);
            j++;
            last++;
          }
          break;
        }
      }
      int left = i - a, right = b - j, count = 0;
      if (left <= right) {
        int move = b - left;
        left = Math.max((right + 1) / (GAP + 1), 16);
        for (int k = a; k < i; k += left) {
          librarySort(k, Math.min(k + left, i), j, pivot, true);
          positions[count++] = k;
        }
        merge(left, i, move, count);
        if (j - i < move - j) {
          while (i < j) {
            move--;
            swap(i, move);
            i++;
          }
          b = move;
        } else {
          while (move > j) {
            move--;
            swap(i, move);
            i++;
          }
          b = i;
        }
      } else {
        int move = a + right;
        right = Math.max((left + 1) / (GAP + 1), 16);
        for (int k = j; k < b; k += right) {
          librarySort(k, Math.min(k + right, b), a, pivot, false);
          positions[count++] = k;
        }
        merge(right, b, a, count);
        if (i - move < j - i) {
          while (move < i) {
            j--;
            swap(move, j);
            move++;
          }
          a = j;
        } else {
          while (j > i) {
            j--;
            swap(move, j);
            move++;
          }
          a = move;
        }
      }
    }
    insertion(a, b);
  }

  public static void sort(int[] array) {
    if (array.length > 1) new flansort(array).execute();
  }

  public static void main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
