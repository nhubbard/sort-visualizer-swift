using System;

public class BinomialHeapSort {
  public static void Sort(int[] arr) {
    int n = arr.Length;

    int index = 2;
    while (index <= n) {
      int maxNode = index;
      while (true) {
        int focus = maxNode;
        int depth = 1;
        while ((focus & depth) == 0) {
          if (arr[focus - depth - 1] > arr[maxNode - 1]) {
            maxNode = focus - depth;
          }
          depth *= 2;
        }
        if (focus != maxNode) {
          (arr[focus - 1], arr[maxNode - 1]) = (arr[maxNode - 1], arr[focus - 1]);
        }
        if (focus == maxNode) {
          break;
        }
      }
      index += 2;
    }

    index = n;
    while (index > 2) {
      int maxNode = index;
      int focus = index;
      int depth = 1;
      while (focus != 0) {
        if ((focus & depth) != 0) {
          if (arr[focus - 1] > arr[maxNode - 1]) {
            maxNode = focus;
          }
          focus -= depth;
        }
        depth *= 2;
      }

      if (maxNode != index) {
        focus = index;
        while (true) {
          (arr[focus - 1], arr[maxNode - 1]) = (arr[maxNode - 1], arr[focus - 1]);
          focus = maxNode;
          int innerDepth = 1;
          while ((focus & innerDepth) == 0) {
            if (arr[focus - innerDepth - 1] > arr[maxNode - 1]) {
              maxNode = focus - innerDepth;
            }
            innerDepth *= 2;
          }
          if (focus == maxNode) {
            break;
          }
        }
      }
      index -= 1;
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
