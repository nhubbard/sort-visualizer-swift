using System;

public class BadSort
{
  private static void Sort(int[] array)
  {
    int currentLen = array.Length;
    for (int i = 0; i < currentLen; i++)
    {
      int shortest = i;

      int j = i;
      while (j < currentLen)
      {
        bool isShortest = true;
        int k = j + 1;
        while (k < currentLen)
        {
          if (array[j] > array[k])
          {
            isShortest = false;
            break;
          }
          k++;
        }
        if (isShortest)
        {
          shortest = j;
          break;
        }
        j++;
      }

      int temp = array[i];
      array[i] = array[shortest];
      array[shortest] = temp;
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