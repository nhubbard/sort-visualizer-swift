using System;

public class SmartGuessSort {
  public static bool PairOk(int[] arr, int[] loops, int i) {
    int a = arr[loops[i]];
    int b = arr[loops[i + 1]];
    if (a < b) {
      return true;
    }
    if (a == b && loops[i] < loops[i + 1]) {
      return true;
    }
    return false;
  }

  public static int FirstFailure(int[] arr, int[] loops, int n) {
    int i = n - 2;
    while (i >= 0 && PairOk(arr, loops, i)) {
      i -= 1;
    }
    return i;
  }

  public static void Sort(int[] arr) {
    int n = arr.Length;
    int[] loops = new int[n];

    while (true) {
      int i = FirstFailure(arr, loops, n);
      if (i < 0) {
        break;
      }
      for (int pos = 0; pos < n; pos++) {
        if (pos >= i && loops[pos] < n - 1) {
          loops[pos] += 1;
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
    int[] array = {0, 39, 21, 62, 91, 14, 23};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
