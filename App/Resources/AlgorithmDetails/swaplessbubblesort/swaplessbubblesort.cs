using System;

public class SwaplessBubbleSort {
  public static int[] Sort(int[] array) {
    var n = array.Length;
    var i = n;
    while (i > 0) {
      var last = 0;
      var pos = 0;
      var comp = array[0];
      for (var j = 1; j < i; j++) {
        if (comp > array[j]) {
          array[j - 1] = array[j];
          last = j;
        } else {
          if (pos + 1 < j) {
            array[j - 1] = comp;
          }
          pos = j;
          comp = array[j];
        }
      }
      array[i - 1] = comp;
      i = last;
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
