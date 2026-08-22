using System;
using System.Collections.Generic;

public class RedBlackTreeSort
{
  private class Node
  {
    public int Value;
    public Node? Left;
    public Node? Right;
    public bool IsRed = true;

    public Node(int value)
    {
      Value = value;
    }
  }

  private class AddResult
  {
    public Node Node;
    public bool NeedsFix;

    public AddResult(Node node, bool needsFix)
    {
      Node = node;
      NeedsFix = needsFix;
    }
  }

  private static bool IsRed(Node? node) => node != null && node.IsRed;

  private static Node SingleRotateRight(Node node)
  {
    Node b = node.Left!;
    node.Left = b.Right;
    b.Right = node;
    b.IsRed = false;
    node.IsRed = true;
    return b;
  }

  private static Node SingleRotateLeft(Node node)
  {
    Node b = node.Right!;
    node.Right = b.Left;
    b.Left = node;
    b.IsRed = false;
    node.IsRed = true;
    return b;
  }

  private static Node DoubleRotateRight(Node node)
  {
    node.Left = SingleRotateLeft(node.Left!);
    return SingleRotateRight(node);
  }

  private static Node DoubleRotateLeft(Node node)
  {
    node.Right = SingleRotateRight(node.Right!);
    return SingleRotateLeft(node);
  }

  private static AddResult Add(Node? node, int value)
  {
    if (node == null)
    {
      return new AddResult(new Node(value), false);
    }

    if (!node.IsRed && IsRed(node.Left) && IsRed(node.Right))
    {
      node.IsRed = true;
      node.Left!.IsRed = false;
      node.Right!.IsRed = false;
    }

    if (value < node.Value)
    {
      AddResult child = Add(node.Left, value);
      node.Left = child.Node;
      if (child.NeedsFix)
      {
        if (IsRed(node.Left!.Left))
        {
          return new AddResult(SingleRotateRight(node), false);
        }
        return new AddResult(DoubleRotateRight(node), false);
      }
      return new AddResult(node, node.IsRed && IsRed(node.Left));
    }
    else
    {
      AddResult child = Add(node.Right, value);
      node.Right = child.Node;
      if (child.NeedsFix)
      {
        if (IsRed(node.Right!.Right))
        {
          return new AddResult(SingleRotateLeft(node), false);
        }
        return new AddResult(DoubleRotateLeft(node), false);
      }
      return new AddResult(node, node.IsRed && IsRed(node.Right));
    }
  }

  private static void Traverse(Node? node, List<int> result)
  {
    if (node == null)
      return;
    Traverse(node.Left, result);
    result.Add(node.Value);
    Traverse(node.Right, result);
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    Node? root = null;
    for (int i = 0; i < n; i++)
    {
      AddResult inserted = Add(root, arr[i]);
      root = inserted.Node;
      root.IsRed = false;
    }

    List<int> result = new List<int>();
    Traverse(root, result);

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