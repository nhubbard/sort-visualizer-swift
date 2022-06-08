using System;

/* TODO: Rename class to match algorithm name. */
public class SortAlgo {
  public static int[] Sort(int[] array) {
    /* TODO: Insert C# algorithm implementation here. */
  }

  public static void Main(String[] args) {
    int[] array = {35, 95, 74, 71, 72, 30, 96, 53, 9, 0};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
