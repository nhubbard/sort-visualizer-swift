import java.util.ArrayDeque;
import java.util.Arrays;
import java.util.Deque;

public class hanoisort {
  private enum StackId {
    TWO,
    THREE
  }

  private static class Sorter {
    private final int[] arr;
    private final int n;
    private final Deque<Integer> stack2 = new ArrayDeque<>();
    private final Deque<Integer> stack3 = new ArrayDeque<>();
    private int sp = 0;
    private int unsorted = 0;
    private int target = 0;
    private int targetMoves = 0;

    Sorter(int[] arr) {
      this.arr = arr;
      this.n = arr.length;
    }

    private void push(StackId id, int value) {
      if (id == StackId.TWO) {
        stack2.push(value);
      } else {
        stack3.push(value);
      }
    }

    private int pop(StackId id) {
      return id == StackId.TWO ? stack2.pop() : stack3.pop();
    }

    private int peek(StackId id) {
      return id == StackId.TWO ? stack2.peek() : stack3.peek();
    }

    private boolean isEmpty(StackId id) {
      return id == StackId.TWO ? stack2.isEmpty() : stack3.isEmpty();
    }

    private int moveFromMain(StackId id, boolean checkUnsorted) {
      int duplicates = 1;
      push(id, arr[sp]);
      sp++;
      boolean endOnLength = sp >= n || (checkUnsorted && sp >= unsorted);
      while (!endOnLength && arr[sp] == peek(id)) {
        duplicates++;
        push(id, arr[sp]);
        sp++;
        endOnLength = sp >= n || (checkUnsorted && sp >= unsorted);
      }
      return duplicates;
    }

    private void moveToMain(StackId id) {
      sp--;
      arr[sp] = pop(id);
      while (!isEmpty(id) && peek(id) == arr[sp]) {
        sp--;
        arr[sp] = pop(id);
      }
    }

    private void moveBetweenStacks(StackId from, StackId to) {
      push(to, pop(from));
      while (!isEmpty(from) && peek(from) == peek(to)) {
        push(to, pop(from));
      }
    }

    private boolean validNumberMoves(int moves) {
      if (moves == 0) {
        return true;
      }
      if (moves % 2 == 0) {
        return false;
      }
      return validNumberMoves(moves / 2);
    }

    private int getHeight(int movesPlus1) {
      if (movesPlus1 == 1) {
        return 0;
      }
      return getHeight(movesPlus1 / 2) + 1;
    }

    private boolean endConMet(int endCon, int moves) {
      if (!validNumberMoves(moves)) {
        return false;
      }
      switch (endCon) {
        case 1:
          return stack2.isEmpty() || target <= stack2.peek();
        case 2:
          return moves == targetMoves;
        case 3:
          return stack2.isEmpty();
        default:
          throw new IllegalStateException("unknown end condition");
      }
    }

    private int hanoi(int startStack, boolean goRight, int endCon) {
      int moves = 0;
      int minPoleLoc = startStack;

      if (!endConMet(endCon, moves)) {
        moves++;
        switch (minPoleLoc) {
          case 1:
            if (goRight) {
              moveFromMain(StackId.TWO, true);
              minPoleLoc = 2;
            } else {
              moveFromMain(StackId.THREE, true);
              minPoleLoc = 3;
            }
            break;
          case 2:
            if (goRight) {
              moveBetweenStacks(StackId.TWO, StackId.THREE);
              minPoleLoc = 3;
            } else {
              moveToMain(StackId.TWO);
              minPoleLoc = 1;
            }
            break;
          default:
            if (goRight) {
              moveToMain(StackId.THREE);
              minPoleLoc = 1;
            } else {
              moveBetweenStacks(StackId.THREE, StackId.TWO);
              minPoleLoc = 2;
            }
            break;
        }
      }

      while (!endConMet(endCon, moves)) {
        moves += 2;
        switch (minPoleLoc) {
          case 1:
            if (!stack2.isEmpty() && (stack3.isEmpty() || stack2.peek() < stack3.peek())) {
              moveBetweenStacks(StackId.TWO, StackId.THREE);
            } else {
              moveBetweenStacks(StackId.THREE, StackId.TWO);
            }
            if (goRight) {
              moveFromMain(StackId.TWO, true);
              minPoleLoc = 2;
            } else {
              moveFromMain(StackId.THREE, true);
              minPoleLoc = 3;
            }
            break;
          case 2:
            if (stack3.isEmpty() || (sp < unsorted && arr[sp] < stack3.peek())) {
              moveFromMain(StackId.THREE, true);
            } else {
              moveToMain(StackId.THREE);
            }
            if (goRight) {
              moveBetweenStacks(StackId.TWO, StackId.THREE);
              minPoleLoc = 3;
            } else {
              moveToMain(StackId.TWO);
              minPoleLoc = 1;
            }
            break;
          default:
            if (stack2.isEmpty() || (sp < unsorted && arr[sp] < stack2.peek())) {
              moveFromMain(StackId.TWO, true);
            } else {
              moveToMain(StackId.TWO);
            }
            if (goRight) {
              moveToMain(StackId.THREE);
              minPoleLoc = 1;
            } else {
              moveBetweenStacks(StackId.THREE, StackId.TWO);
              minPoleLoc = 2;
            }
            break;
        }
      }

      return moves;
    }

    private void removeFromMainStack() {
      target = arr[sp];
      int moves = hanoi(2, true, 1);
      int height = getHeight(moves + 1);
      targetMoves = moves;
      boolean evenHeight = height % 2 == 0;

      if (evenHeight) {
        hanoi(1, true, 2);
      }
      unsorted += moveFromMain(StackId.TWO, false);
      hanoi(3, evenHeight, 2);
    }

    private void returnToMainStack() {
      int moves = hanoi(2, true, 3);
      int height = getHeight(moves + 1);
      if (height % 2 == 1) {
        targetMoves = moves;
        hanoi(3, true, 2);
      }
    }

    void run() {
      while (unsorted < n) {
        removeFromMainStack();
      }
      returnToMainStack();
    }
  }

  public static void sort(int[] arr) {
    if (arr.length <= 1) {
      return;
    }
    new Sorter(arr).run();
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
