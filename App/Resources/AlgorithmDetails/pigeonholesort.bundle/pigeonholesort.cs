using System;
using System.Linq;

public class PigeonholeSort {
  public static int[] Sort(int[] array) {
    int min = array.Min();
    int max = array.Max();
    int size = max - min + 1;

    var holes = new int[size];
    foreach (var value in array) {
      holes[value - min]++;
    }

    var output = new int[array.Length];
    var j = 0;
    for (var count = 0; count < size; count++) {
      while (holes[count] > 0) {
        holes[count]--;
        output[j] = count + min;
        j++;
      }
    }
    return output;
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    array = Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
