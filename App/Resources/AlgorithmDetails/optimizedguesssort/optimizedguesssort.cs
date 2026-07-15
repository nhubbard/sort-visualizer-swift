using System;

public class OptimizedGuessSort {
  public static bool IsValid(int[] arr, int[] loops, int n) {
    for (int i = 0; i < n - 1; i++) {
      int a = arr[loops[i]];
      int b = arr[loops[i + 1]];
      if (a < b || (a == b && loops[i] < loops[i + 1])) {
        continue;
      }
      return false;
    }
    return true;
  }

  public static void Sort(int[] arr) {
    int n = arr.Length;
    int[] loops = new int[n];

    while (!IsValid(arr, loops, n)) {
      for (int pos = 0; pos < n; pos++) {
        if (loops[pos] < n - 1) {
          loops[pos]++;
          break;
        } else {
          loops[pos] = 0;
        }
      }
    }

    int[] mapped = new int[n];
    for (int i = 0; i < n; i++) {
      mapped[i] = arr[loops[i]];
    }
    for (int i = 0; i < n; i++) {
      arr[i] = mapped[i];
    }
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 14};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
