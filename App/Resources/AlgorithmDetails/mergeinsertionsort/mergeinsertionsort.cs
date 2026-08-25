using System;
using System.Collections.Generic;

public class MergeInsertionSort
{
  // Tags a value with its original index so a pending element can find its way back to the
  // right chain partner even after the chain has been recursively reordered.
  struct Elem
  {
    public int Value;
    public int Index;

    public Elem(int value, int index)
    {
      Value = value;
      Index = index;
    }
  }

  // Inserts elem into the already-sorted seq via binary search, comparing by value only.
  static void BinaryInsert(List<Elem> seq, Elem elem)
  {
    int lo = 0;
    int hi = seq.Count;
    while (lo < hi)
    {
      int mid = (lo + hi) / 2;
      if (seq[mid].Value <= elem.Value)
      {
        lo = mid + 1;
      }
      else
      {
        hi = mid;
      }
    }
    seq.Insert(lo, elem);
  }

  // Returns, as 1-based positions into a list of `count` not-yet-placed pending elements, the
  // order to insert them in: 2, then 4 and 3, then 10 down to 5, then 20 down to 11, and so on.
  // This Jacobsthal-number grouping is what makes merge-insertion sort comparison-optimal.
  // Position 1 is never included -- it is always placed for free before any of these
  // insertions happen.
  static List<int> JacobsthalInsertionOrder(int count)
  {
    int maxPosition = count + 1;
    List<int> order = new List<int>();
    int placedThrough = 1;
    int k = 2;
    while (placedThrough < maxPosition)
    {
      int sign = (k % 2 == 0) ? 1 : -1;
      int t = ((1 << (k + 1)) + sign) / 3;
      int groupEnd = Math.Min(t - 1, maxPosition);
      for (int position = groupEnd; position > placedThrough; position--)
      {
        order.Add(position);
      }
      placedThrough = groupEnd;
      k++;
    }
    return order;
  }

  // Splits items into chain (the larger element of each adjacent pair), partnerOf (mapping a
  // chain element's original index to its paired, smaller element), and extra (a leftover
  // element with no partner when items has odd length).
  static (List<Elem>, Dictionary<int, Elem>, Elem?) PairUp(List<Elem> items)
  {
    List<Elem> chain = new List<Elem>();
    Dictionary<int, Elem> partnerOf = new Dictionary<int, Elem>();
    int i = 0;
    int n = items.Count;
    while (i + 1 < n)
    {
      Elem a = items[i];
      Elem b = items[i + 1];
      Elem small = a.Value <= b.Value ? a : b;
      Elem large = a.Value <= b.Value ? b : a;
      partnerOf[large.Index] = small;
      chain.Add(large);
      i += 2;
    }
    Elem? extra = i < n ? items[i] : (Elem?)null;
    return (chain, partnerOf, extra);
  }

  // Sorts a list of Elem by value. The index tags are what let a pending element find its way
  // back to the right chain partner after the chain has been recursively reordered by this
  // same function one level down.
  static List<Elem> SortTagged(List<Elem> items)
  {
    if (items.Count <= 1)
    {
      return new List<Elem>(items);
    }

    var (chain, partnerOf, extra) = PairUp(items);
    List<Elem> sortedChain = SortTagged(chain);

    // The pending partner of the smallest chain element is guaranteed smaller than every
    // other chain element too, so it can go straight to the front with no comparison at all.
    List<Elem> sequence = new List<Elem> { partnerOf[sortedChain[0].Index] };
    sequence.AddRange(sortedChain);

    List<Elem> remaining = new List<Elem>();
    for (int k = 1; k < sortedChain.Count; k++)
    {
      remaining.Add(partnerOf[sortedChain[k].Index]);
    }
    if (extra != null)
    {
      remaining.Add(extra.Value);
    }

    foreach (int position in JacobsthalInsertionOrder(remaining.Count))
    {
      BinaryInsert(sequence, remaining[position - 2]);
    }

    return sequence;
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n < 2) return;
    List<Elem> tagged = new List<Elem>();
    for (int i = 0; i < n; i++)
    {
      tagged.Add(new Elem(arr[i], i));
    }
    List<Elem> sortedTagged = SortTagged(tagged);
    for (int i = 0; i < n; i++)
    {
      arr[i] = sortedTagged[i].Value;
    }
  }

  public static void Main(String[] args)
  {
    int[] array = {
      34, 7, 23, 90, 12, 56, 3, 45, 78, 21, 66, 9, 50, 15, 88, 40, 61, 5, 33, 72, 18, 95, 27, 60
    };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}