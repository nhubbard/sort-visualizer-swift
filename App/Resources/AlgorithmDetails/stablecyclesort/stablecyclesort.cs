using System;

public class StableCycleSort {
  private static int Destination(int[] arr, bool[] flagged, int a, int b1, int b) {
    var heldValue = arr[a];
    var d = a;
    var e = 0;
    for (var i = a + 1; i < b; i++) {
      if (arr[i] < heldValue) {
        d++;
      } else if (i < b1 && !flagged[i] && arr[i] == heldValue) {
        e++;
      }
    }
    while (flagged[d] || e > 0) {
      if (!flagged[d]) e--;
      d++;
    }
    return d;
  }

  public static int[] Sort(int[] array) {
    var n = array.Length;
    if (n <= 1) return array;
    var flagged = new bool[n];
    for (var i = 0; i < n - 1; i++) {
      if (flagged[i]) continue;
      var j = i;
      do {
        var k = Destination(array, flagged, i, j, n);
        (array[i], array[k]) = (array[k], array[i]);
        flagged[k] = true;
        j = k;
      } while (j != i);
    }
    return array;
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
