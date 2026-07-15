using System;

public class BinomialSmoothSort {
  public static int Height(int node) {
    int count = 0;
    while ((node >> count) % 2 == 1) {
      count += 1;
    }
    return count;
  }

  public static void Thrift(int[] arr, int node, bool parentFlag, bool rootFlag) {
    bool isRoot = rootFlag && (node >= (1 << Height(node)));
    if (!isRoot && !parentFlag) {
      return;
    }

    int choice = Height(node) - (isRoot ? 0 : 1);
    if (parentFlag) {
      for (int child = choice - 1; child >= 0; child--) {
        if (arr[node - (1 << choice)] <= arr[node - (1 << child)]) {
          choice = child;
        }
      }
    }

    if (arr[node - (1 << choice)] <= arr[node]) {
      return;
    }

    (arr[node], arr[node - (1 << choice)]) = (arr[node - (1 << choice)], arr[node]);
    int nextNode = node - (1 << choice);
    Thrift(arr, nextNode, nextNode % 2 == 1, choice == Height(node));
  }

  public static void Sort(int[] arr) {
    int n = arr.Length;

    int node = 1;
    while (node < n) {
      Thrift(arr, node, node % 2 == 1, (node + (1 << Height(node))) >= n);
      node += 1;
    }

    node -= (node - 1) % 2;
    while (node > 2) {
      for (int child = Height(node) - 1; child >= 0; child--) {
        Thrift(arr, node - (1 << child), false, true);
      }
      node -= 2;
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
