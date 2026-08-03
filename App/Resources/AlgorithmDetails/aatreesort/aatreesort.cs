using System;
using System.Collections.Generic;

public class AaTreeSort
{
  private class Node
  {
    public int Value;
    public int Level;
    public Node? Left;
    public Node? Right;

    public Node(int value)
    {
      Value = value;
      Level = 0;
    }
  }

  private static int NodeLevel(Node? node)
  {
    return node == null ? -1 : node.Level;
  }

  private static Node Skew(Node node)
  {
    if (node.Left == null)
    {
      return node;
    }
    Node l = node.Left;
    node.Left = l.Right;
    l.Right = node;
    return l;
  }

  private static Node Split(Node node)
  {
    if (node.Right == null)
    {
      return node;
    }
    Node r = node.Right;
    node.Right = r.Left;
    r.Left = node;
    r.Level++;
    return r;
  }

  private static Node Add(Node? node, int value)
  {
    if (node == null)
    {
      return new Node(value);
    }
    if (value < node.Value)
    {
      node.Left = Add(node.Left, value);
      if (NodeLevel(node.Left) == node.Level)
      {
        if (node.Level != NodeLevel(node.Right))
        {
          return Skew(node);
        }
        node.Level++;
        return node;
      }
      return node;
    }
    else
    {
      node.Right = Add(node.Right, value);
      if (NodeLevel(node.Right?.Right) == node.Level)
      {
        return Split(node);
      }
      return node;
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
      root = Add(root, arr[i]);
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