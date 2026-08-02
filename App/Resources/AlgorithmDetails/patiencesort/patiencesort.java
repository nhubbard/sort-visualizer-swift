import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.PriorityQueue;

public class patiencesort {
  public static void sort(int[] arr) {
    int n = arr.length;
    List<List<Integer>> piles = new ArrayList<>();
    List<Integer> tops = new ArrayList<>();

    for (int x : arr) {
      // binary search: leftmost pile whose top is >= x
      int lo = 0;
      int hi = piles.size();
      while (lo < hi) {
        int mid = (lo + hi) / 2;
        if (tops.get(mid) >= x) {
          hi = mid;
        } else {
          lo = mid + 1;
        }
      }
      if (lo == piles.size()) {
        List<Integer> pile = new ArrayList<>();
        pile.add(x);
        piles.add(pile);
        tops.add(x);
      } else {
        piles.get(lo).add(x);
        tops.set(lo, x);
      }
    }

    PriorityQueue<int[]> heap = new PriorityQueue<>((a, b) -> Integer.compare(a[0], b[0]));
    for (int i = 0; i < piles.size(); i++) {
      heap.add(new int[] {tops.get(i), i});
    }

    int[] result = new int[n];
    int resultIndex = 0;
    while (!heap.isEmpty()) {
      int[] entry = heap.poll();
      int pileIndex = entry[1];
      List<Integer> pile = piles.get(pileIndex);
      int value = pile.remove(pile.size() - 1);
      result[resultIndex++] = value;
      if (!pile.isEmpty()) {
        heap.add(new int[] {pile.get(pile.size() - 1), pileIndex});
      }
    }

    System.arraycopy(result, 0, arr, 0, n);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
