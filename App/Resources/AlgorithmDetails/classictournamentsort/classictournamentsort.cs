using System;

class ClassicTournamentSort
{
  static int CeilPow2(int value)
  {
    int r = 1;
    while (r < value)
      r *= 2;
    return r;
  }

  static void Sort(int[] array)
  {
    int n = array.Length;
    if (n <= 1)
      return;

    int size = CeilPow2(n) - 1;
    int mod = n % 2;
    int treeSize = n + size + mod;
    int[] tree = new int[treeSize];
    for (int i = 0; i < treeSize; i++)
      tree[i] = -1;

    bool TreeCompare(int a, int b) => array[tree[a]] <= array[tree[b]];

    for (int i = size; i < treeSize - mod; i++)
      tree[i] = i - size;

    int j = size;
    int k = treeSize - mod;
    while (j > 0)
    {
      int i = j;
      while (i + 1 < k)
      {
        tree[i / 2] = TreeCompare(i, i + 1) ? tree[i] : tree[i + 1];
        i += 2;
      }
      if (i < k)
        tree[i / 2] = tree[i];
      j /= 2;
      k /= 2;
    }

    int FindNext()
    {
      int path = tree[0] + size;
      while (path > 0)
      {
        tree[path] = -1;
        path = (path - 1) / 2;
      }

      int node = tree[0] + size;
      while (node > 0)
      {
        int sibling = node % 2 == 1 ? node + 1 : node - 1;
        bool nodeValid = tree[node] != -1;
        bool siblingValid = tree[sibling] != -1;
        int winner;
        if (nodeValid && siblingValid)
        {
          winner = node < sibling
              ? (TreeCompare(node, sibling) ? tree[node] : tree[sibling])
              : (TreeCompare(sibling, node) ? tree[sibling] : tree[node]);
        }
        else if (nodeValid)
        {
          winner = tree[node];
        }
        else if (siblingValid)
        {
          winner = tree[sibling];
        }
        else
        {
          winner = -1;
        }
        node = (node - 1) / 2;
        if (winner != -1)
          tree[node] = winner;
      }
      return array[tree[0]];
    }

    int[] output = new int[n];
    output[0] = array[tree[0]];
    for (int i = 1; i < n; i++)
      output[i] = FindNext();
    Array.Copy(output, array, n);
  }

  static void Main()
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    Console.WriteLine("[" + string.Join(", ", array) + "]");
  }
}