using System;
using System.Collections.Generic;

public class HanoiSort
{
  private enum StackId
  {
    Two,
    Three
  }

  private class Sorter
  {
    private readonly int[] arr;
    private readonly int n;
    private readonly Stack<int> stack2 = new Stack<int>();
    private readonly Stack<int> stack3 = new Stack<int>();
    private int sp;
    private int unsorted;
    private int target;
    private int targetMoves;

    public Sorter(int[] arr)
    {
      this.arr = arr;
      this.n = arr.Length;
    }

    private void Push(StackId id, int value)
    {
      if (id == StackId.Two)
        stack2.Push(value);
      else
        stack3.Push(value);
    }

    private int Pop(StackId id)
    {
      return id == StackId.Two ? stack2.Pop() : stack3.Pop();
    }

    private int Peek(StackId id)
    {
      return id == StackId.Two ? stack2.Peek() : stack3.Peek();
    }

    private bool IsEmpty(StackId id)
    {
      return id == StackId.Two ? stack2.Count == 0 : stack3.Count == 0;
    }

    private int MoveFromMain(StackId id, bool checkUnsorted)
    {
      int duplicates = 1;
      Push(id, arr[sp]);
      sp++;
      bool endOnLength = sp >= n || (checkUnsorted && sp >= unsorted);
      while (!endOnLength && arr[sp] == Peek(id))
      {
        duplicates++;
        Push(id, arr[sp]);
        sp++;
        endOnLength = sp >= n || (checkUnsorted && sp >= unsorted);
      }
      return duplicates;
    }

    private void MoveToMain(StackId id)
    {
      sp--;
      arr[sp] = Pop(id);
      while (!IsEmpty(id) && Peek(id) == arr[sp])
      {
        sp--;
        arr[sp] = Pop(id);
      }
    }

    private void MoveBetweenStacks(StackId from, StackId to)
    {
      Push(to, Pop(from));
      while (!IsEmpty(from) && Peek(from) == Peek(to))
      {
        Push(to, Pop(from));
      }
    }

    private bool ValidNumberMoves(int moves)
    {
      if (moves == 0)
        return true;
      if (moves % 2 == 0)
        return false;
      return ValidNumberMoves(moves / 2);
    }

    private int GetHeight(int movesPlus1)
    {
      if (movesPlus1 == 1)
        return 0;
      return GetHeight(movesPlus1 / 2) + 1;
    }

    private bool EndConMet(int endCon, int moves)
    {
      if (!ValidNumberMoves(moves))
        return false;
      switch (endCon)
      {
        case 1:
          return stack2.Count == 0 || target <= stack2.Peek();
        case 2:
          return moves == targetMoves;
        case 3:
          return stack2.Count == 0;
        default:
          throw new InvalidOperationException("unknown end condition");
      }
    }

    private int Hanoi(int startStack, bool goRight, int endCon)
    {
      int moves = 0;
      int minPoleLoc = startStack;

      if (!EndConMet(endCon, moves))
      {
        moves++;
        switch (minPoleLoc)
        {
          case 1:
            if (goRight)
            {
              MoveFromMain(StackId.Two, true);
              minPoleLoc = 2;
            }
            else
            {
              MoveFromMain(StackId.Three, true);
              minPoleLoc = 3;
            }
            break;
          case 2:
            if (goRight)
            {
              MoveBetweenStacks(StackId.Two, StackId.Three);
              minPoleLoc = 3;
            }
            else
            {
              MoveToMain(StackId.Two);
              minPoleLoc = 1;
            }
            break;
          default:
            if (goRight)
            {
              MoveToMain(StackId.Three);
              minPoleLoc = 1;
            }
            else
            {
              MoveBetweenStacks(StackId.Three, StackId.Two);
              minPoleLoc = 2;
            }
            break;
        }
      }

      while (!EndConMet(endCon, moves))
      {
        moves += 2;
        switch (minPoleLoc)
        {
          case 1:
            if (stack2.Count > 0 && (stack3.Count == 0 || stack2.Peek() < stack3.Peek()))
            {
              MoveBetweenStacks(StackId.Two, StackId.Three);
            }
            else
            {
              MoveBetweenStacks(StackId.Three, StackId.Two);
            }
            if (goRight)
            {
              MoveFromMain(StackId.Two, true);
              minPoleLoc = 2;
            }
            else
            {
              MoveFromMain(StackId.Three, true);
              minPoleLoc = 3;
            }
            break;
          case 2:
            if (stack3.Count == 0 || (sp < unsorted && arr[sp] < stack3.Peek()))
            {
              MoveFromMain(StackId.Three, true);
            }
            else
            {
              MoveToMain(StackId.Three);
            }
            if (goRight)
            {
              MoveBetweenStacks(StackId.Two, StackId.Three);
              minPoleLoc = 3;
            }
            else
            {
              MoveToMain(StackId.Two);
              minPoleLoc = 1;
            }
            break;
          default:
            if (stack2.Count == 0 || (sp < unsorted && arr[sp] < stack2.Peek()))
            {
              MoveFromMain(StackId.Two, true);
            }
            else
            {
              MoveToMain(StackId.Two);
            }
            if (goRight)
            {
              MoveToMain(StackId.Three);
              minPoleLoc = 1;
            }
            else
            {
              MoveBetweenStacks(StackId.Three, StackId.Two);
              minPoleLoc = 2;
            }
            break;
        }
      }

      return moves;
    }

    private void RemoveFromMainStack()
    {
      target = arr[sp];
      int moves = Hanoi(2, true, 1);
      int height = GetHeight(moves + 1);
      targetMoves = moves;
      bool evenHeight = height % 2 == 0;

      if (evenHeight)
      {
        Hanoi(1, true, 2);
      }
      unsorted += MoveFromMain(StackId.Two, false);
      Hanoi(3, evenHeight, 2);
    }

    private void ReturnToMainStack()
    {
      int moves = Hanoi(2, true, 3);
      int height = GetHeight(moves + 1);
      if (height % 2 == 1)
      {
        targetMoves = moves;
        Hanoi(3, true, 2);
      }
    }

    public void Run()
    {
      while (unsorted < n)
      {
        RemoveFromMainStack();
      }
      ReturnToMainStack();
    }
  }

  public static void Sort(int[] arr)
  {
    if (arr.Length <= 1)
      return;
    new Sorter(arr).Run();
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}