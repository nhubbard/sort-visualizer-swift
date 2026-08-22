#nullable disable
using System;

public class SplaySort
{
  private static int idx;

  private class Node
  {
    public int Key;
    public Node Left;
    public Node Right;

    public Node(int key)
    {
      Key = key;
    }
  }

  private static Node LeftRotate(Node x)
  {
    Node y = x.Right;
    x.Right = y.Left;
    y.Left = x;
    return y;
  }

  private static Node RightRotate(Node x)
  {
    Node y = x.Left;
    x.Left = y.Right;
    y.Right = x;
    return y;
  }

  private static Node Splay(Node root, int key)
  {
    if (root == null)
    {
      return root;
    }
    if (root.Key > key)
    {
      if (root.Left == null)
      {
        return root;
      }
      if (root.Left.Key > key)
      {
        root.Left.Left = Splay(root.Left.Left, key);
        root = RightRotate(root);
      }
      else
      {
        root.Left.Right = Splay(root.Left.Right, key);
        if (root.Left.Right != null)
        {
          root.Left = LeftRotate(root.Left);
        }
      }
      return root.Left == null ? root : RightRotate(root);
    }
    else
    {
      if (root.Right == null)
      {
        return root;
      }
      if (root.Right.Key > key)
      {
        root.Right.Left = Splay(root.Right.Left, key);
        if (root.Right.Left != null)
        {
          root.Right = RightRotate(root.Right);
        }
      }
      else
      {
        root.Right.Right = Splay(root.Right.Right, key);
        root = LeftRotate(root);
      }
      return root.Right == null ? root : LeftRotate(root);
    }
  }

  private static Node InsertRec(Node root, int key)
  {
    if (root == null)
    {
      return new Node(key);
    }
    root = Splay(root, key);
    Node n = new Node(key);
    if (root.Key > key)
    {
      n.Right = root;
      n.Left = root.Left;
      root.Left = null;
    }
    else
    {
      n.Left = root;
      n.Right = root.Right;
      root.Right = null;
    }
    return n;
  }

  private static void Traverse(Node node, int[] result)
  {
    if (node != null)
    {
      Traverse(node.Left, result);
      result[idx++] = node.Key;
      Traverse(node.Right, result);
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    Node root = null;
    foreach (int x in arr)
    {
      root = InsertRec(root, x);
    }
    int[] result = new int[n];
    idx = 0;
    Traverse(root, result);
    Array.Copy(result, arr, n);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}