private enum class StackId { TWO, THREE }

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 1) return

  val stack2 = ArrayDeque<Int>()
  val stack3 = ArrayDeque<Int>()

  fun push(id: StackId, value: Int) {
    if (id == StackId.TWO) stack2.addLast(value) else stack3.addLast(value)
  }

  fun pop(id: StackId): Int = if (id == StackId.TWO) stack2.removeLast() else stack3.removeLast()

  fun peek(id: StackId): Int? = if (id == StackId.TWO) stack2.lastOrNull() else stack3.lastOrNull()

  fun isEmpty(id: StackId): Boolean = if (id == StackId.TWO) stack2.isEmpty() else stack3.isEmpty()

  var sp = 0
  var unsorted = 0
  var target = 0
  var targetMoves = 0

  fun moveFromMain(id: StackId, checkUnsorted: Boolean): Int {
    var duplicates = 1
    push(id, arr[sp])
    sp += 1
    var endOnLength = sp >= n || (checkUnsorted && sp >= unsorted)
    while (!endOnLength && arr[sp] == peek(id)) {
      duplicates += 1
      push(id, arr[sp])
      sp += 1
      endOnLength = sp >= n || (checkUnsorted && sp >= unsorted)
    }
    return duplicates
  }

  fun moveToMain(id: StackId) {
    sp -= 1
    arr[sp] = pop(id)
    while (!isEmpty(id) && peek(id) == arr[sp]) {
      sp -= 1
      arr[sp] = pop(id)
    }
  }

  fun moveBetweenStacks(from: StackId, to: StackId) {
    push(to, pop(from))
    while (!isEmpty(from) && peek(from) == peek(to)) {
      push(to, pop(from))
    }
  }

  fun validNumberMoves(moves: Int): Boolean {
    if (moves == 0) return true
    if (moves % 2 == 0) return false
    return validNumberMoves(moves / 2)
  }

  fun getHeight(movesPlus1: Int): Int {
    if (movesPlus1 == 1) return 0
    return getHeight(movesPlus1 / 2) + 1
  }

  fun endConMet(endCon: Int, moves: Int): Boolean {
    if (!validNumberMoves(moves)) return false
    return when (endCon) {
      1 -> stack2.isEmpty() || target <= stack2.last()
      2 -> moves == targetMoves
      3 -> stack2.isEmpty()
      else -> throw IllegalStateException("unknown end condition")
    }
  }

  fun hanoi(startStack: Int, goRight: Boolean, endCon: Int): Int {
    var moves = 0
    var minPoleLoc = startStack

    if (!endConMet(endCon, moves)) {
      moves += 1
      when (minPoleLoc) {
        1 -> {
          if (goRight) {
            moveFromMain(StackId.TWO, true)
            minPoleLoc = 2
          } else {
            moveFromMain(StackId.THREE, true)
            minPoleLoc = 3
          }
        }

        2 -> {
          if (goRight) {
            moveBetweenStacks(StackId.TWO, StackId.THREE)
            minPoleLoc = 3
          } else {
            moveToMain(StackId.TWO)
            minPoleLoc = 1
          }
        }

        else -> {
          if (goRight) {
            moveToMain(StackId.THREE)
            minPoleLoc = 1
          } else {
            moveBetweenStacks(StackId.THREE, StackId.TWO)
            minPoleLoc = 2
          }
        }
      }
    }

    while (!endConMet(endCon, moves)) {
      moves += 2
      when (minPoleLoc) {
        1 -> {
          if (stack2.isNotEmpty() && (stack3.isEmpty() || stack2.last() < stack3.last())) {
            moveBetweenStacks(StackId.TWO, StackId.THREE)
          } else {
            moveBetweenStacks(StackId.THREE, StackId.TWO)
          }
          if (goRight) {
            moveFromMain(StackId.TWO, true)
            minPoleLoc = 2
          } else {
            moveFromMain(StackId.THREE, true)
            minPoleLoc = 3
          }
        }

        2 -> {
          if (stack3.isEmpty() || (sp < unsorted && arr[sp] < stack3.last())) {
            moveFromMain(StackId.THREE, true)
          } else {
            moveToMain(StackId.THREE)
          }
          if (goRight) {
            moveBetweenStacks(StackId.TWO, StackId.THREE)
            minPoleLoc = 3
          } else {
            moveToMain(StackId.TWO)
            minPoleLoc = 1
          }
        }

        else -> {
          if (stack2.isEmpty() || (sp < unsorted && arr[sp] < stack2.last())) {
            moveFromMain(StackId.TWO, true)
          } else {
            moveToMain(StackId.TWO)
          }
          if (goRight) {
            moveToMain(StackId.THREE)
            minPoleLoc = 1
          } else {
            moveBetweenStacks(StackId.THREE, StackId.TWO)
            minPoleLoc = 2
          }
        }
      }
    }

    return moves
  }

  fun removeFromMainStack() {
    target = arr[sp]
    val moves = hanoi(2, true, 1)
    val height = getHeight(moves + 1)
    targetMoves = moves
    val evenHeight = height % 2 == 0

    if (evenHeight) {
      hanoi(1, true, 2)
    }
    unsorted += moveFromMain(StackId.TWO, false)
    hanoi(3, evenHeight, 2)
  }

  fun returnToMainStack() {
    val moves = hanoi(2, true, 3)
    val height = getHeight(moves + 1)
    if (height % 2 == 1) {
      targetMoves = moves
      hanoi(3, true, 2)
    }
  }

  while (unsorted < n) {
    removeFromMainStack()
  }
  returnToMainStack()
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
