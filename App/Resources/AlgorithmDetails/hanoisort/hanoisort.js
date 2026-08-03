function sort(arr) {
  const n = arr.length;
  if (n <= 1) {
    return;
  }

  const STACK_TWO = "two";
  const STACK_THREE = "three";

  const stack2 = [];
  const stack3 = [];

  function push(id, value) {
    if (id === STACK_TWO) {
      stack2.push(value);
    } else {
      stack3.push(value);
    }
  }

  function pop(id) {
    return id === STACK_TWO ? stack2.pop() : stack3.pop();
  }

  function peek(id) {
    const stack = id === STACK_TWO ? stack2 : stack3;
    return stack.length === 0 ? undefined : stack[stack.length - 1];
  }

  function isEmpty(id) {
    return (id === STACK_TWO ? stack2 : stack3).length === 0;
  }

  let sp = 0;
  let unsorted = 0;
  let target = 0;
  let targetMoves = 0;

  function moveFromMain(id, checkUnsorted) {
    let duplicates = 1;
    push(id, arr[sp]);
    sp += 1;
    let endOnLength = sp >= n || (checkUnsorted && sp >= unsorted);
    while (!endOnLength && arr[sp] === peek(id)) {
      duplicates += 1;
      push(id, arr[sp]);
      sp += 1;
      endOnLength = sp >= n || (checkUnsorted && sp >= unsorted);
    }
    return duplicates;
  }

  function moveToMain(id) {
    sp -= 1;
    arr[sp] = pop(id);
    while (!isEmpty(id) && peek(id) === arr[sp]) {
      sp -= 1;
      arr[sp] = pop(id);
    }
  }

  function moveBetweenStacks(from, to) {
    push(to, pop(from));
    while (!isEmpty(from) && peek(from) === peek(to)) {
      push(to, pop(from));
    }
  }

  function validNumberMoves(moves) {
    if (moves === 0) {
      return true;
    }
    if (moves % 2 === 0) {
      return false;
    }
    return validNumberMoves(Math.floor(moves / 2));
  }

  function getHeight(movesPlus1) {
    if (movesPlus1 === 1) {
      return 0;
    }
    return getHeight(Math.floor(movesPlus1 / 2)) + 1;
  }

  function endConMet(endCon, moves) {
    if (!validNumberMoves(moves)) {
      return false;
    }
    switch (endCon) {
      case 1:
        return stack2.length === 0 || target <= stack2[stack2.length - 1];
      case 2:
        return moves === targetMoves;
      case 3:
        return stack2.length === 0;
      default:
        throw new Error("unknown end condition");
    }
  }

  function hanoi(startStack, goRight, endCon) {
    let moves = 0;
    let minPoleLoc = startStack;

    if (!endConMet(endCon, moves)) {
      moves += 1;
      switch (minPoleLoc) {
        case 1:
          if (goRight) {
            moveFromMain(STACK_TWO, true);
            minPoleLoc = 2;
          } else {
            moveFromMain(STACK_THREE, true);
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
          if (
            stack2.length > 0 &&
            (stack3.length === 0 ||
              stack2[stack2.length - 1] < stack3[stack3.length - 1])
          ) {
            moveBetweenStacks(STACK_TWO, STACK_THREE);
          } else {
            moveBetweenStacks(STACK_THREE, STACK_TWO);
          }
          if (goRight) {
            moveFromMain(STACK_TWO, true);
            minPoleLoc = 2;
          } else {
            moveFromMain(STACK_THREE, true);
            minPoleLoc = 3;
          }
          break;
        case 2:
          if (
            stack3.length === 0 ||
            (sp < unsorted && arr[sp] < stack3[stack3.length - 1])
          ) {
            moveFromMain(STACK_THREE, true);
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
          if (
            stack2.length === 0 ||
            (sp < unsorted && arr[sp] < stack2[stack2.length - 1])
          ) {
            moveFromMain(STACK_TWO, true);
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

  function removeFromMainStack() {
    target = arr[sp];
    const moves = hanoi(2, true, 1);
    const height = getHeight(moves + 1);
    targetMoves = moves;
    const evenHeight = height % 2 === 0;

    if (evenHeight) {
      hanoi(1, true, 2);
    }
    unsorted += moveFromMain(STACK_TWO, false);
    hanoi(3, evenHeight, 2);
  }

  function returnToMainStack() {
    const moves = hanoi(2, true, 3);
    const height = getHeight(moves + 1);
    if (height % 2 === 1) {
      targetMoves = moves;
      hanoi(3, true, 2);
    }
  }

  while (unsorted < n) {
    removeFromMainStack();
  }
  returnToMainStack();
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
