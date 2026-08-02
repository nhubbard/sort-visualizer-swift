using System;
using System.Collections.Generic;

public class PatienceSort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    List<List<int>> piles = new List<List<int>>();
    List<int> tops = new List<int>();

    foreach (int x in arr)
    {
      // binary search: leftmost pile whose top is >= x
      int lo = 0;
      int hi = piles.Count;
      while (lo < hi)
      {
        int mid = (lo + hi) / 2;
        if (tops[mid] >= x)
        {
          hi = mid;
        }
        else
        {
          lo = mid + 1;
        }
      }
      if (lo == piles.Count)
      {
        piles.Add(new List<int> { x });
        tops.Add(x);
      }
      else
      {
        piles[lo].Add(x);
        tops[lo] = x;
      }
    }

    PriorityQueue<int, int> heap = new PriorityQueue<int, int>();
    for (int i = 0; i < piles.Count; i++)
    {
      heap.Enqueue(i, tops[i]);
    }

    int[] result = new int[n];
    int resultIndex = 0;
    while (heap.Count > 0)
    {
      int pileIndex = heap.Dequeue();
      List<int> pile = piles[pileIndex];
      int value = pile[pile.Count - 1];
      pile.RemoveAt(pile.Count - 1);
      result[resultIndex++] = value;
      if (pile.Count > 0)
      {
        heap.Enqueue(pileIndex, pile[pile.Count - 1]);
      }
    }

    Array.Copy(result, arr, n);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}