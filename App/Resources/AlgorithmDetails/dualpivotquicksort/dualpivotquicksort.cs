using System;

public class DualPivotQuickSort {
  public static (int, int) Partition(int[] array, int low, int high) {
    if (array[low] > array[high]) {
      (array[low], array[high]) = (array[high], array[low]);
    }
    var j = low + 1;
    var g = high - 1;
    var k = low + 1;
    var p = array[low];
    var q = array[high];
    while (k <= g) {
      if (array[k] < p) {
        (array[k], array[j]) = (array[j], array[k]);
        j++;
      } else if (array[k] >= q) {
        while (array[g] > q && k < g) {
          g--;
        }
        (array[k], array[g]) = (array[g], array[k]);
        g--;
        if (array[k] < p) {
          (array[k], array[j]) = (array[j], array[k]);
          j++;
        }
      }
      k++;
    }
    j--;
    g++;
    (array[low], array[j]) = (array[j], array[low]);
    (array[high], array[g]) = (array[g], array[high]);
    return (j, g);
  }

  public static int[] Sort(int[] array, int low, int high) {
    if (low < high) {
      var (j, g) = Partition(array, low, high);
      Sort(array, low, j - 1);
      Sort(array, j + 1, g - 1);
      Sort(array, g + 1, high);
    }
    return array;
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array, 0, array.Length - 1);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
