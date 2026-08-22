using System;

public class BogoBogoSort
{
  // A literal Bogo Bogo Sort re-derives the "is it sorted?" answer through a recursive sort of
  // its own, so its real cost grows worse than n! squared -- even a handful of elements can take
  // an unreasonable amount of time. To keep this example runnable, the true recursive algorithm
  // below is only ever applied to a small leading slice of the array (ChaosLimit elements); the
  // rest is finished with an ordinary insertion sort, and the two already-sorted pieces are
  // merged back together at the end. The random reshuffle is also replaced with a deterministic,
  // never-repeating permutation walk, so neither piece can wander into an unbounded random
  // search.
  private const int ChaosLimit = 5;

  // Advances arr to its next lexicographic permutation in place. Returns false (after resetting
  // arr to its first, fully ascending permutation) once every arrangement has been visited -- a
  // deterministic stand-in for "shuffle the array at random".
  private static bool NextPermutation(int[] arr)
  {
    int n = arr.Length;
    int i = n - 2;
    while (i >= 0 && arr[i] >= arr[i + 1])
    {
      i--;
    }
    if (i < 0)
    {
      Array.Reverse(arr);
      return false;
    }
    int j = n - 1;
    while (arr[j] <= arr[i])
    {
      j--;
    }
    (arr[i], arr[j]) = (arr[j], arr[i]);
    Array.Reverse(arr, i + 1, n - i - 1);
    return true;
  }

  // The heart of the joke: rather than scanning arr once, decide whether it is sorted by copying
  // it, recursively Bogo-Bogo-sorting the copy's first n - 1 elements with this exact same
  // process one level down, reshuffling the whole copy until its last two elements land in
  // order, and comparing the result against the original. A match means the copy is now the true
  // sorted arrangement of the same values, which is only possible if arr was already sorted.
  private static bool BogoBogoIsSorted(int[] arr)
  {
    int n = arr.Length;
    if (n <= 1)
    {
      return true;
    }
    int[] copy = (int[])arr.Clone();
    int[] prefix = new int[n - 1];
    Array.Copy(copy, prefix, n - 1);
    BogoBogoSortRange(prefix);
    Array.Copy(prefix, copy, n - 1);
    int candidate = 0;
    while (copy[n - 2] > copy[n - 1])
    {
      (copy[candidate], copy[n - 1]) = (copy[n - 1], copy[candidate]);
      candidate++;
      Array.Copy(copy, prefix, n - 1);
      BogoBogoSortRange(prefix);
      Array.Copy(prefix, copy, n - 1);
    }
    for (int k = 0; k < n; k++)
    {
      if (copy[k] != arr[k])
      {
        return false;
      }
    }
    return true;
  }

  private static void BogoBogoSortRange(int[] arr)
  {
    while (!BogoBogoIsSorted(arr))
    {
      NextPermutation(arr);
    }
  }

  private static void InsertionSort(int[] arr)
  {
    for (int i = 1; i < arr.Length; i++)
    {
      int key = arr[i];
      int j = i - 1;
      while (j >= 0 && arr[j] > key)
      {
        arr[j + 1] = arr[j];
        j--;
      }
      arr[j + 1] = key;
    }
  }

  private static int[] MergeSorted(int[] a, int[] b)
  {
    int[] merged = new int[a.Length + b.Length];
    int i = 0, j = 0, k = 0;
    while (i < a.Length && j < b.Length)
    {
      merged[k++] = a[i] <= b[j] ? a[i++] : b[j++];
    }
    while (i < a.Length)
    {
      merged[k++] = a[i++];
    }
    while (j < b.Length)
    {
      merged[k++] = b[j++];
    }
    return merged;
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int limit = Math.Min(ChaosLimit, n);
    int[] chaos = new int[limit];
    Array.Copy(arr, chaos, limit);
    int[] rest = new int[n - limit];
    Array.Copy(arr, limit, rest, 0, n - limit);

    BogoBogoSortRange(chaos); // the real, recursive-check algorithm -- kept tiny on purpose
    InsertionSort(rest); // an ordinary fast sort for the rest of the array

    int[] merged = MergeSorted(chaos, rest);
    Array.Copy(merged, arr, n);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}