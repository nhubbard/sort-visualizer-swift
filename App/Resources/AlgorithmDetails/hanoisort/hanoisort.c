#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

typedef enum { STACK_TWO, STACK_THREE } StackId;

static int *arr;
static int n;
static int *stack2;
static int stack2Top;
static int *stack3;
static int stack3Top;
static int sp;
static int unsorted;
static int target;
static int targetMoves;

void printList(int items[], int size) {
  for (int i = 0; i < size; i++) {
    if (i == 0) {
      printf("[%d, ", items[i]);
    } else if (i != size - 1) {
      printf("%d, ", items[i]);
    } else {
      printf("%d]", items[i]);
    }
  }
}

static void push(StackId id, int value) {
  if (id == STACK_TWO) {
    stack2[stack2Top++] = value;
  } else {
    stack3[stack3Top++] = value;
  }
}

static int popStack(StackId id) {
  if (id == STACK_TWO) {
    return stack2[--stack2Top];
  }
  return stack3[--stack3Top];
}

static int peekStack(StackId id) {
  if (id == STACK_TWO) {
    return stack2[stack2Top - 1];
  }
  return stack3[stack3Top - 1];
}

static int isEmptyStack(StackId id) {
  if (id == STACK_TWO) {
    return stack2Top == 0;
  }
  return stack3Top == 0;
}

static int moveFromMain(StackId id, int checkUnsorted) {
  int duplicates = 1;
  push(id, arr[sp]);
  sp++;
  int endOnLength = sp >= n || (checkUnsorted && sp >= unsorted);
  while (!endOnLength && arr[sp] == peekStack(id)) {
    duplicates++;
    push(id, arr[sp]);
    sp++;
    endOnLength = sp >= n || (checkUnsorted && sp >= unsorted);
  }
  return duplicates;
}

static void moveToMain(StackId id) {
  sp--;
  arr[sp] = popStack(id);
  while (!isEmptyStack(id) && peekStack(id) == arr[sp]) {
    sp--;
    arr[sp] = popStack(id);
  }
}

static void moveBetweenStacks(StackId from, StackId to) {
  push(to, popStack(from));
  while (!isEmptyStack(from) && peekStack(from) == peekStack(to)) {
    push(to, popStack(from));
  }
}

static int validNumberMoves(int moves) {
  if (moves == 0) {
    return 1;
  }
  if (moves % 2 == 0) {
    return 0;
  }
  return validNumberMoves(moves / 2);
}

static int getHeight(int movesPlus1) {
  if (movesPlus1 == 1) {
    return 0;
  }
  return getHeight(movesPlus1 / 2) + 1;
}

static int endConMet(int endCon, int moves) {
  if (!validNumberMoves(moves)) {
    return 0;
  }
  switch (endCon) {
  case 1:
    return stack2Top == 0 || target <= stack2[stack2Top - 1];
  case 2:
    return moves == targetMoves;
  case 3:
    return stack2Top == 0;
  default:
    fprintf(stderr, "unknown end condition\n");
    exit(1);
  }
}

static int hanoi(int startStack, int goRight, int endCon) {
  int moves = 0;
  int minPoleLoc = startStack;

  if (!endConMet(endCon, moves)) {
    moves++;
    switch (minPoleLoc) {
    case 1:
      if (goRight) {
        moveFromMain(STACK_TWO, 1);
        minPoleLoc = 2;
      } else {
        moveFromMain(STACK_THREE, 1);
        minPoleLoc = 3;
      }
      break;
    case 2:
      if (goRight) {
        moveBetweenStacks(STACK_TWO, STACK_THREE);
        minPoleLoc = 3;
      } else {
        moveToMain(STACK_TWO);
        minPoleLoc = 1;
      }
      break;
    default:
      if (goRight) {
        moveToMain(STACK_THREE);
        minPoleLoc = 1;
      } else {
        moveBetweenStacks(STACK_THREE, STACK_TWO);
        minPoleLoc = 2;
      }
      break;
    }
  }

  while (!endConMet(endCon, moves)) {
    moves += 2;
    switch (minPoleLoc) {
    case 1:
      if (stack2Top > 0 &&
          (stack3Top == 0 || stack2[stack2Top - 1] < stack3[stack3Top - 1])) {
        moveBetweenStacks(STACK_TWO, STACK_THREE);
      } else {
        moveBetweenStacks(STACK_THREE, STACK_TWO);
      }
      if (goRight) {
        moveFromMain(STACK_TWO, 1);
        minPoleLoc = 2;
      } else {
        moveFromMain(STACK_THREE, 1);
        minPoleLoc = 3;
      }
      break;
    case 2:
      if (stack3Top == 0 ||
          (sp < unsorted && arr[sp] < stack3[stack3Top - 1])) {
        moveFromMain(STACK_THREE, 1);
      } else {
        moveToMain(STACK_THREE);
      }
      if (goRight) {
        moveBetweenStacks(STACK_TWO, STACK_THREE);
        minPoleLoc = 3;
      } else {
        moveToMain(STACK_TWO);
        minPoleLoc = 1;
      }
      break;
    default:
      if (stack2Top == 0 ||
          (sp < unsorted && arr[sp] < stack2[stack2Top - 1])) {
        moveFromMain(STACK_TWO, 1);
      } else {
        moveToMain(STACK_TWO);
      }
      if (goRight) {
        moveToMain(STACK_THREE);
        minPoleLoc = 1;
      } else {
        moveBetweenStacks(STACK_THREE, STACK_TWO);
        minPoleLoc = 2;
      }
      break;
    }
  }

  return moves;
}

static void removeFromMainStack(void) {
  target = arr[sp];
  int moves = hanoi(2, 1, 1);
  int height = getHeight(moves + 1);
  targetMoves = moves;
  int evenHeight = height % 2 == 0;

  if (evenHeight) {
    hanoi(1, 1, 2);
  }
  unsorted += moveFromMain(STACK_TWO, 0);
  hanoi(3, evenHeight, 2);
}

static void returnToMainStack(void) {
  int moves = hanoi(2, 1, 3);
  int height = getHeight(moves + 1);
  if (height % 2 == 1) {
    targetMoves = moves;
    hanoi(3, 1, 2);
  }
}

void sort(int a[], int size) {
  if (size <= 1) {
    return;
  }

  arr = a;
  n = size;
  stack2 = malloc(sizeof(int) * n);
  stack3 = malloc(sizeof(int) * n);
  stack2Top = 0;
  stack3Top = 0;
  sp = 0;
  unsorted = 0;
  target = 0;
  targetMoves = 0;

  while (unsorted < n) {
    removeFromMainStack();
  }
  returnToMainStack();

  free(stack2);
  free(stack3);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
