import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class librarysort {
  private static final int EMPTY = Integer.MIN_VALUE;

  private static final class Library {
    private int[] slots = new int[0];
    private int capacity = 0;
    // Physical `slots` index of each placed element, ascending by both position and value.
    private final List<Integer> positions = new ArrayList<>();

    private void rebalance() {
      int count = positions.size();
      int newCapacity = Math.max(2, count * 2);
      int[] newSlots = new int[newCapacity];
      Arrays.fill(newSlots, EMPTY);
      List<Integer> newPositions = new ArrayList<>();
      for (int i = 0; i < count; i++) {
        int pos = positions.get(i);
        int newPos = i * 2;
        newSlots[newPos] = slots[pos];
        newPositions.add(newPos);
      }
      slots = newSlots;
      positions.clear();
      positions.addAll(newPositions);
      capacity = newCapacity;
    }

    private void insert(int value) {
      if (positions.size() == capacity) {
        rebalance();
      }

      // Upper-bound binary search: first slot whose value is strictly greater than `value`.
      int lo = 0;
      int hi = positions.size();
      while (lo < hi) {
        int mid = (lo + hi) / 2;
        if (slots[positions.get(mid)] > value) {
          hi = mid;
        } else {
          lo = mid + 1;
        }
      }
      int k = lo;
      int targetPos = k == 0 ? 0 : positions.get(k - 1) + 1;

      if (!(targetPos == capacity || slots[targetPos] != EMPTY)) {
        slots[targetPos] = value;
        positions.add(k, targetPos);
        return;
      }

      // Either targetPos is already occupied, or targetPos == capacity (new maximum, no room
      // left of the structure's end). Search BOTH directions for the nearest gap and shift
      // whichever side is closer.
      int leftGap = targetPos - 1;
      while (leftGap >= 0 && slots[leftGap] != EMPTY) {
        leftGap--;
      }
      int rightGap = targetPos;
      while (rightGap < capacity && slots[rightGap] != EMPTY) {
        rightGap++;
      }
      int leftDistance = leftGap >= 0 ? targetPos - leftGap : Integer.MAX_VALUE;
      int rightDistance = rightGap < capacity ? rightGap - targetPos : Integer.MAX_VALUE;

      if (rightDistance <= leftDistance) {
        int i = rightGap;
        while (i > targetPos) {
          slots[i] = slots[i - 1];
          i--;
        }
        for (int idx = k; idx < k + (rightGap - targetPos); idx++) {
          positions.set(idx, positions.get(idx) + 1);
        }
        slots[targetPos] = value;
        positions.add(k, targetPos);
      } else {
        int shiftCount = (targetPos - 1) - leftGap;
        int i = leftGap;
        while (i < targetPos - 1) {
          slots[i] = slots[i + 1];
          i++;
        }
        for (int idx = k - shiftCount; idx < k; idx++) {
          positions.set(idx, positions.get(idx) - 1);
        }
        slots[targetPos - 1] = value;
        positions.add(k, targetPos - 1);
      }
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n <= 1) {
      return;
    }

    Library library = new Library();
    for (int v : arr) {
      library.insert(v);
    }

    for (int i = 0; i < n; i++) {
      arr[i] = library.slots[library.positions.get(i)];
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
