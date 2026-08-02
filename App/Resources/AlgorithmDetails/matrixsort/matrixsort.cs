using System;

public class MatrixSort
{
  private static int DirCompareVal(int left, int right, bool dir)
  {
    int res;
    if (left > right)
      res = 1;
    else if (left < right)
      res = -1;
    else
      res = 0;
    return dir ? res : -res;
  }

  private static void GapReverse(int[] arr, int start, int end, int gap)
  {
    int i = start, j = end;
    while (i < j)
    {
      (arr[i], arr[j - gap]) = (arr[j - gap], arr[i]);
      i += gap;
      j -= gap;
    }
  }

  private static bool InsertLast(int[] arr, int a, int b, int gap, bool dir)
  {
    bool did = false;
    int key = arr[b];
    int j = b - gap;
    while (j >= a && DirCompareVal(key, arr[j], dir) < 0)
    {
      arr[j + gap] = arr[j];
      did = true;
      j -= gap;
    }
    arr[j + gap] = key;
    return did;
  }

  private readonly struct MatrixShape
  {
    public readonly int Width;
    public readonly bool InsertLast;

    public MatrixShape(int width, bool insertLast)
    {
      Width = width;
      InsertLast = insertLast;
    }
  }

  private static MatrixShape GetMatrixDims(int length)
  {
    int dim = (int)Math.Sqrt(length);
    bool insertLastFlag = dim * dim == length - 1;
    while (length % dim != 0)
    {
      dim -= 1;
    }
    int width = dim;
    int height = length / dim;
    bool unbalanced = (width == 1) != (height == 1);
    return new MatrixShape(width, unbalanced || insertLastFlag);
  }

  private static bool MatrixSortRec(int[] arr, int start, int end, int gap, bool dir)
  {
    int length = (end - start) / gap;
    if (length < 2)
    {
      return false;
    }
    else if (length <= 16)
    {
      bool did = false;
      int i = start;
      while (i < end)
      {
        did = InsertLast(arr, start, i, gap, dir) || did;
        i += gap;
      }
      return did;
    }
    else
    {
      MatrixShape matShape = GetMatrixDims(length);
      if (matShape.InsertLast)
      {
        bool did1 = MatrixSortRec(arr, start, end - gap, gap, dir);
        bool did2 = InsertLast(arr, start, end - gap, gap, dir);
        return did1 || did2;
      }

      int i = start + matShape.Width * gap;
      while (i < end)
      {
        GapReverse(arr, i, i + matShape.Width * gap, gap);
        i += 2 * matShape.Width * gap;
      }

      bool did = false;
      bool newdid = true;
      while (newdid)
      {
        newdid = false;
        bool curdir = dir;
        i = start;
        while (i < end)
        {
          newdid = MatrixSortRec(arr, i, i + matShape.Width * gap, gap, curdir) || newdid;
          did = did || newdid;
          curdir = !curdir;
          i += matShape.Width * gap;
        }

        newdid = false;
        for (int k = 0; k < matShape.Width; k++)
        {
          newdid = MatrixSortRec(arr, start + k * gap, end + k * gap, gap * matShape.Width, dir) || newdid;
          did = did || newdid;
        }
      }
      i = start + matShape.Width * gap;
      while (i < end)
      {
        GapReverse(arr, i, i + matShape.Width * gap, gap);
        i += 2 * matShape.Width * gap;
      }

      return did;
    }
  }

  public static void Sort(int[] arr)
  {
    MatrixSortRec(arr, 0, arr.Length, 1, true);
  }

  public static void Main(String[] args)
  {
    int[] array = { 15, 3, 22, 8, 19, 1, 24, 11, 6, 20, 9, 17, 2, 14, 23, 5, 18, 0, 12, 21, 7, 16, 4, 13, 10 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}