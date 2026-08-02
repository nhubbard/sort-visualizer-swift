using System;
using System.Collections.Generic;

public class TreeSort
{
  private class Node
  {
    public int Pointer;
    public Node? Left;
    public Node? Right;

    public Node(int pointer)
    {
      Pointer = pointer;
    }
  }

  private static Node Add(int[] arr, Node? node, int addPtr)
  {
    if (node == null)
    {
      return new Node(addPtr);
    }
    if (arr[addPtr] < arr[node.Pointer])
    {
      node.Left = Add(arr, node.Left, addPtr);
    }
    else
    {
      node.Right = Add(arr, node.Right, addPtr);
    }
    return node;
  }

  private static void Traverse(int[] arr, Node? node, List<int> result)
  {
    if (node == null)
      return;
    Traverse(arr, node.Left, result);
    result.Add(arr[node.Pointer]);
    Traverse(arr, node.Right, result);
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    Node? root = null;
    for (int i = 0; i < n; i++)
    {
      root = Add(arr, root, i);
    }

    List<int> result = new List<int>();
    Traverse(arr, root, result);

    for (int i = 0; i < n; i++)
    {
      arr[i] = result[i];
    }
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}