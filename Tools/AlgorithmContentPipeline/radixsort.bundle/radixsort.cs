using System;
using System.Linq;

public class RadixSort {
  public static void Sort(int[] arr) {
    int n = arr.Length;
    int[,] bucket = new int[10, 10];
    int[] bucketCount = new int[10];
    int i, j, k, r, nop = 0, divisor = 1, lar, pass;
    lar = arr.Max();
    while (lar > 0) {
      nop++;
      lar /= 10;
    }
    for (pass = 0; pass < nop; pass++) {
      for (i = 0; i < 10; i++) {
        bucketCount[i] = 0;
      }
      for (i = 0; i < n; i++) {
        r = (arr[i] / divisor) % 10;
        bucket[r, bucketCount[r]] = arr[i];
        bucketCount[r] += 1;
      }
      i = 0;
      for (k = 0; k < 10; k++) {
        for (j = 0; j < bucketCount[k]; j++) {
          arr[i] = bucket[k, j];
          i++;
        }
      }
      divisor *= 10;
    }
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}