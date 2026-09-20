import java.util.Arrays;

public class remisort {
  private final int[] a;
  private final int n, block, runLength, runs;
  private final int[] keys;
  private int[] buffer, heap, position, destination;
  private int size;

  public static void sort(int[] a) {
    new remisort(a).execute();
  }

  private remisort(int[] values) {
    a = values;
    n = a.length;
    int low = 0, high = Math.min(n, 1291);
    while (low < high) {
      int middle = (low + high) / 2;
      if (middle * middle * middle >= n) high = middle;
      else low = middle + 1;
    }
    block = low;
    runLength = block * block;
    runs = n < 2 ? 0 : (n - 1) / runLength + 1;
    keys = new int[runs < 2 ? n : runLength];
    for (int i = 0; i < keys.length; i++) keys[i] = i;
  }

  private boolean greater(int x, int y, int start) {
    return a[start + x] > a[start + y] || a[start + x] == a[start + y] && x > y;
  }

  private void tableSift(int root, int length, int start, int item) {
    int j = root;
    while (2 * j + 1 < length) {
      j = 2 * j + 1;
      if (j + 1 < length && greater(keys[j + 1], keys[j], start)) j++;
    }
    while (j > root && greater(item, keys[j], start)) j = (j - 1) / 2;
    while (j > root) {
      int old = keys[j];
      keys[j] = item;
      item = old;
      j = (j - 1) / 2;
    }
    keys[root] = item;
  }

  private void tableSort(int start, int end) {
    int length = end - start;
    if (length < 2) return;
    for (int i = (length - 1) / 2; i >= 0; i--) tableSift(i, length, start, keys[i]);
    for (int i = length - 1; i > 0; i--) {
      int item = keys[i];
      keys[i] = keys[0];
      tableSift(0, i, start, item);
    }
    for (int i = 0; i < length; i++) {
      if (keys[i] == i) continue;
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
  }

  private boolean less(int x, int y) {
    return a[position[x]] < a[position[y]] || a[position[x]] == a[position[y]] && x < y;
  }

  private void sift(int item, int start, int length) {
    int root = start;
    while (2 * root + 2 < length) {
      int left = 2 * root + 1;
      int child = less(heap[left], heap[left + 1]) ? left : left + 1;
      if (!less(heap[child], item)) break;
      heap[root] = heap[child];
      root = child;
    }
    int last = 2 * root + 1;
    if (last < length && less(heap[last], item)) {
      heap[root] = heap[last];
      root = last;
    }
    heap[root] = item;
  }

  private void advance(int run) {
    position[run]++;
    if (position[run] == Math.min((run + 1) * runLength, n)) {
      size--;
      sift(heap[size], 0, size);
    } else sift(heap[0], 0, size);
  }

  private void execute() {
    if (n < 2) return;
    if (runs < 2) {
      tableSort(0, n);
      return;
    }
    buffer = new int[runLength];
    heap = new int[runs];
    position = new int[runs];
    destination = new int[runs];
    for (int run = 0; run < runs; run++) {
      int start = run * runLength;
      tableSort(start, Math.min(start + runLength, n));
      heap[run] = run;
      position[run] = destination[run] = start;
    }
    size = runs;
    for (int i = (runs - 1) / 2; i >= 0; i--) sift(heap[i], i, size);
    for (int i = 0; i < runLength; i++) {
      int run = heap[0];
      buffer[i] = a[position[run]];
      advance(run);
    }
    int t = 0, count = 0, cursor = 0;
    while (position[cursor] - destination[cursor] < block) cursor++;
    do {
      int run = heap[0];
      a[destination[cursor]++] = a[position[run]];
      advance(run);
      count++;
      if (count == block) {
        keys[t++] = cursor > 0 ? destination[cursor] / block - block - 1 : -1;
        cursor = 0;
        count = 0;
        while (position[cursor] - destination[cursor] < block) cursor++;
      }
    } while (size > 0);
    int end = n;
    while (count > 0) {
      count--;
      destination[cursor]--;
      a[--end] = a[destination[cursor]];
    }
    position[runs - 1] = end;
    keys[keys.length - 1] = -1;
    t = 0;
    while (keys[t] != -1) t++;
    int source = 0;
    for (int run = 1; run < runs && source < destination[0]; run++) {
      while (destination[run] < position[run]) {
        keys[t++] = destination[run] / block - block;
        while (keys[t] != -1) t++;
        for (int x = 0; x < block; x++) a[destination[run] + x] = a[source + x];
        destination[run] += block;
        source += block;
      }
    }
    System.arraycopy(buffer, 0, a, 0, runLength);
    int blocks = (end - runLength) / block;
    for (int i = 0; i < blocks; i++) {
      if (keys[i] == i) continue;
      System.arraycopy(a, runLength + i * block, buffer, 0, block);
      int j = i, next = keys[i];
      do {
        System.arraycopy(a, runLength + next * block, a, runLength + j * block, block);
        keys[j] = j;
        j = next;
        next = keys[next];
      } while (next != i);
      System.arraycopy(buffer, 0, a, runLength + j * block, block);
      keys[j] = j;
    }
  }

  public static void main(String[] args) {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
