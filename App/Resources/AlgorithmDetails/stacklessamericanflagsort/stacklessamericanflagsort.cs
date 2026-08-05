using System;

public class StacklessAmericanFlagSort
{
  const int Radix = 4;

  static int GetDigit(int value, int place)
  {
    for (int p = 0; p < place; p++)
    {
      value /= Radix;
    }
    return value % Radix;
  }

  static int Shift(int value, int places)
  {
    for (int p = 0; p < places; p++)
    {
      value /= Radix;
    }
    return value;
  }

  // Turns the raw per-bucket counts already accumulated in `counts` into
  // starting offsets, then places every element in [start, end) by
  // following displacement cycles, one bucket at a time.
  static int Distribute(int[] arr, int[] counts, int[] offsets, int start, int end, int place)
  {
    for (int i = 1; i < Radix; i++)
    {
      counts[i] += counts[i - 1];
      offsets[i] = counts[i - 1];
    }

    for (int bucket = 0; bucket < Radix - 1; bucket++)
    {
      int position = start + offsets[bucket];
      if (counts[bucket] > offsets[bucket])
      {
        int held = arr[position];
        do
        {
          int digit = GetDigit(held, place);
          counts[digit]--;
          int displaced = arr[start + counts[digit]];
          arr[start + counts[digit]] = held;
          held = displaced;
        } while (counts[bucket] > offsets[bucket]);
      }
    }

    int split = start + offsets[1];
    for (int i = 0; i < Radix; i++)
    {
      counts[i] = 0;
      offsets[i] = 0;
    }
    return split;
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n < 2)
    {
      return;
    }

    int q = 0;
    int probe = Radix;
    int maxValue = arr[0];
    foreach (int v in arr)
    {
      if (v > maxValue)
      {
        maxValue = v;
      }
    }
    while (probe <= maxValue)
    {
      q++;
      probe *= Radix;
    }

    int[] counts = new int[Radix];
    int[] offsets = new int[Radix];

    // i/b track the bounds of whichever range is currently active, q the
    // digit place being distributed on, and m a counter that mirrors how
    // many bucket boundaries have already been walked at the current
    // depth, standing in for the call stack a recursive walk would need.
    int m = 0;
    int i = 0;
    int b = n;

    for (int j = i; j < b; j++)
    {
      counts[GetDigit(arr[j], q)]++;
    }

    while (i < n)
    {
      int p = (b - i < 1) ? i : Distribute(arr, counts, offsets, i, b, q);

      if (q == 0)
      {
        m += Radix;
        int t = m / Radix;
        while (t % Radix == 0)
        {
          t /= Radix;
          q++;
        }

        i = b;
        while (b < n && Shift(arr[b], q + 1) == Shift(m, q + 1))
        {
          counts[GetDigit(arr[b], q)]++;
          b++;
        }
      }
      else
      {
        b = p;
        q--;
        for (int j = i; j < b; j++)
        {
          counts[GetDigit(arr[j], q)]++;
        }
      }
    }
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}