using System;
using System.Collections.Generic;

public class AvlTreeSort
{
  private class Node
  {
    public int Value;
    public Node? Left;
    public Node? Right;
    public int Balance;

    public Node(int value)
    {
      Value = value;
    }
  }

  private class AddResult
  {
    public Node Node;
    public bool HeightChanged;

    public AddResult(Node node, bool heightChanged)
    {
      Node = node;
      HeightChanged = heightChanged;
    }
  }

  private static Node SingleRotateRight(Node node)
  {
    Node b = node.Left!;
    node.Left = b.Right;
    b.Right = node;
    node.Balance = 0;
    b.Balance = 0;
    return b;
  }

  private static Node SingleRotateLeft(Node node)
  {
    Node b = node.Right!;
    node.Right = b.Left;
    b.Left = node;
    node.Balance = 0;
    b.Balance = 0;
    return b;
  }

  private static Node DoubleRotateRight(Node node)
  {
    int oldBBalance = node.Left!.Right!.Balance;
    node.Left = SingleRotateLeft(node.Left);
    Node b = SingleRotateRight(node);
    if (oldBBalance == -1)
      b.Right!.Balance = 1;
    if (oldBBalance == 1)
      b.Left!.Balance = -1;
    return b;
  }

  private static Node DoubleRotateLeft(Node node)
  {
    int oldBBalance = node.Right!.Left!.Balance;
    node.Right = SingleRotateRight(node.Right);
    Node b = SingleRotateLeft(node);
    if (oldBBalance == -1)
      b.Right!.Balance = 1;
    if (oldBBalance == 1)
      b.Left!.Balance = -1;
    return b;
  }

  private static AddResult HeightChangeLeft(Node node)
  {
    if (node.Balance != -1)
    {
      node.Balance -= 1;
      return new AddResult(node, node.Balance == -1);
    }
    if (node.Left!.Balance == -1)
    {
      return new AddResult(SingleRotateRight(node), false);
    }
    return new AddResult(DoubleRotateRight(node), false);
  }

  private static AddResult HeightChangeRight(Node node)
  {
    if (node.Balance != 1)
    {
      node.Balance += 1;
      return new AddResult(node, node.Balance == 1);
    }
    if (node.Right!.Balance == 1)
    {
      return new AddResult(SingleRotateLeft(node), false);
    }
    return new AddResult(DoubleRotateLeft(node), false);
  }

  private static AddResult Add(Node? node, int value)
  {
    if (node == null)
    {
      return new AddResult(new Node(value), true);
    }
    if (value < node.Value)
    {
      AddResult result = Add(node.Left, value);
      node.Left = result.Node;
      if (result.HeightChanged)
      {
        return HeightChangeLeft(node);
      }
      return new AddResult(node, false);
    }
    else
    {
      AddResult result = Add(node.Right, value);
      node.Right = result.Node;
      if (result.HeightChanged)
      {
        return HeightChangeRight(node);
      }
      return new AddResult(node, false);
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
    Node? root = null;
    foreach (int value in arr)
    {
      root = Add(root, value).Node;
    }

    List<int> result = new List<int>();
    Traverse(root, result);

    for (int i = 0; i < arr.Length; i++)
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