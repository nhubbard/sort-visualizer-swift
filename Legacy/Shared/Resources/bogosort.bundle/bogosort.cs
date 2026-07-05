using System;

public class BogoSort {
  public static Random r = new Random();
  
  public static bool IsSorted(int[] arr) {
    for (int i = 1; i < arr.Length; i++) {
      if (arr[i - 1] > arr[i]) {
        return false;
      }
    }
    return true;
  }
  
  public static void Shuffle(int[] arr) {
    int n = arr.Length;
    for (int i = 0; i < n; i++) {
      int a = r.Next(n);
      int b = r.Next(n);
      (arr[a], arr[b]) = (arr[b], arr[a]);
    }
  }
  
  public static void Sort(int[] arr) {
    int n = arr.Length;
    while (!IsSorted(arr)) {
      Shuffle(arr);
    }
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
