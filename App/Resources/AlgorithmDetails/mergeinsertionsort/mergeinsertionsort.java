import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class mergeinsertionsort {
  // Tags a value with its original index so a pending element can find its way back to the
  // right chain partner even after the chain has been recursively reordered.
  static class Elem {
    final int value;
    final int index;

    Elem(int value, int index) {
      this.value = value;
      this.index = index;
    }
  }

  static class PairResult {
    final List<Elem> chain;
    final Map<Integer, Elem> partnerOf;
    final Elem extra;

    PairResult(List<Elem> chain, Map<Integer, Elem> partnerOf, Elem extra) {
      this.chain = chain;
      this.partnerOf = partnerOf;
      this.extra = extra;
    }
  }

  // Inserts elem into the already-sorted seq via binary search, comparing by value only.
  static void binaryInsert(List<Elem> seq, Elem elem) {
    int lo = 0;
    int hi = seq.size();
    while (lo < hi) {
      int mid = (lo + hi) / 2;
      if (seq.get(mid).value <= elem.value) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    seq.add(lo, elem);
  }

  // Returns, as 1-based positions into a list of `count` not-yet-placed pending elements, the
  // order to insert them in: 2, then 4 and 3, then 10 down to 5, then 20 down to 11, and so on.
  // This Jacobsthal-number grouping is what makes merge-insertion sort comparison-optimal.
  // Position 1 is never included -- it is always placed for free before any of these
  // insertions happen.
  static List<Integer> jacobsthalInsertionOrder(int count) {
    int maxPosition = count + 1;
    List<Integer> order = new ArrayList<>();
    int placedThrough = 1;
    int k = 2;
    while (placedThrough < maxPosition) {
      int sign = (k % 2 == 0) ? 1 : -1;
      int t = ((1 << (k + 1)) + sign) / 3;
      int groupEnd = Math.min(t - 1, maxPosition);
      for (int position = groupEnd; position > placedThrough; position--) {
        order.add(position);
      }
      placedThrough = groupEnd;
      k++;
    }
    return order;
  }

  // Splits items into chain (the larger element of each adjacent pair), partnerOf (mapping a
  // chain element's original index to its paired, smaller element), and extra (a leftover
  // element with no partner when items has odd length).
  static PairResult pairUp(List<Elem> items) {
    List<Elem> chain = new ArrayList<>();
    Map<Integer, Elem> partnerOf = new HashMap<>();
    int i = 0;
    int n = items.size();
    while (i + 1 < n) {
      Elem a = items.get(i);
      Elem b = items.get(i + 1);
      Elem small = a.value <= b.value ? a : b;
      Elem large = a.value <= b.value ? b : a;
      partnerOf.put(large.index, small);
      chain.add(large);
      i += 2;
    }
    Elem extra = i < n ? items.get(i) : null;
    return new PairResult(chain, partnerOf, extra);
  }

  // Sorts a list of Elem by value. The index tags are what let a pending element find its way
  // back to the right chain partner after the chain has been recursively reordered by this
  // same function one level down.
  static List<Elem> sortTagged(List<Elem> items) {
    if (items.size() <= 1) {
      return new ArrayList<>(items);
    }

    PairResult paired = pairUp(items);
    List<Elem> sortedChain = sortTagged(paired.chain);

    // The pending partner of the smallest chain element is guaranteed smaller than every
    // other chain element too, so it can go straight to the front with no comparison at all.
    List<Elem> sequence = new ArrayList<>();
    sequence.add(paired.partnerOf.get(sortedChain.get(0).index));
    sequence.addAll(sortedChain);

    List<Elem> remaining = new ArrayList<>();
    for (int k = 1; k < sortedChain.size(); k++) {
      remaining.add(paired.partnerOf.get(sortedChain.get(k).index));
    }
    if (paired.extra != null) {
      remaining.add(paired.extra);
    }

    for (int position : jacobsthalInsertionOrder(remaining.size())) {
      binaryInsert(sequence, remaining.get(position - 2));
    }

    return sequence;
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n < 2) {
      return;
    }
    List<Elem> tagged = new ArrayList<>();
    for (int i = 0; i < n; i++) {
      tagged.add(new Elem(arr[i], i));
    }
    List<Elem> sortedTagged = sortTagged(tagged);
    for (int i = 0; i < n; i++) {
      arr[i] = sortedTagged.get(i).value;
    }
  }

  public static void main(String[] args) {
    int[] array = {
      34, 7, 23, 90, 12, 56, 3, 45, 78, 21, 66, 9, 50, 15, 88, 40, 61, 5, 33, 72, 18, 95, 27, 60
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
