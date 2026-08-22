using System;

public class SimplisticGravitySort
{
  private static void TransferTo(int[] arr, int[] aux, int minValue, int index)
  {
    int pointer = 0;
    while (arr[index] > minValue)
    {
      arr[index]--;
      aux[pointer]++;
      pointer++;
    }
  }

  private static void TransferFrom(int[] arr, int[] aux, int auxLength, int index)
  {
    int pointer = 0;
    while (pointer < auxLength && aux[pointer] != 0)
    {
      arr[index]++;
      aux[pointer]--;
      pointer++;
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n == 0)
      return;

    int minValue = arr[0];
    int maxValue = arr[0];
    for (int i = 1; i < n; i++)
    {
      if (arr[i] < minValue)
        minValue = arr[i];
      if (arr[i] > maxValue)
        maxValue = arr[i];
    }
    int auxLength = maxValue - minValue;
    int[] aux = new int[auxLength];

    for (int i = 0; i < n; i++)
    {
      TransferTo(arr, aux, minValue, i);
    }
    for (int i = n - 1; i >= 0; i--)
    {
      TransferFrom(arr, aux, auxLength, i);
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