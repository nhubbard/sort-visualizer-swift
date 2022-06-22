using System;

/* TODO: Rename class to match algorithm name. */
public class SortAlgo {
  public static void Sort(int[] arr) {
    int n = arr.Length;
    /* TODO: Insert C# algorithm implementation here. */
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}