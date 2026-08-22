#include <cstdio>
#include <stdexcept>
#include <vector>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

enum class StackId { Two, Three };

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

class HanoiSorter {
public:
  HanoiSorter(int *arr, int n) : arr_(arr), n_(n) {}

  void run() {
    while (unsorted_ < n_) {
      removeFromMainStack();
    }
    returnToMainStack();
  }

private:
  int *arr_;
  int n_;
  std::vector<int> stack2_;
  std::vector<int> stack3_;
  int sp_ = 0;
  int unsorted_ = 0;
  int target_ = 0;
  int targetMoves_ = 0;

  void push(StackId id, int value) {
    if (id == StackId::Two) {
      stack2_.push_back(value);
    } else {
      stack3_.push_back(value);
    }
  }

  int pop(StackId id) {
    std::vector<int> &stack = id == StackId::Two ? stack2_ : stack3_;
    int value = stack.back();
    stack.pop_back();
    return value;
  }

  int peek(StackId id) {
    std::vector<int> &stack = id == StackId::Two ? stack2_ : stack3_;
    return stack.back();
  }

  bool isEmpty(StackId id) {
    return (id == StackId::Two ? stack2_ : stack3_).empty();
  }

  int moveFromMain(StackId id, bool checkUnsorted) {
    int duplicates = 1;
    push(id, arr_[sp_]);
    sp_++;
    bool endOnLength = sp_ >= n_ || (checkUnsorted && sp_ >= unsorted_);
    while (!endOnLength && arr_[sp_] == peek(id)) {
      duplicates++;
      push(id, arr_[sp_]);
      sp_++;
      endOnLength = sp_ >= n_ || (checkUnsorted && sp_ >= unsorted_);
    }
    return duplicates;
  }

  void moveToMain(StackId id) {
    sp_--;
    arr_[sp_] = pop(id);
    while (!isEmpty(id) && peek(id) == arr_[sp_]) {
      sp_--;
      arr_[sp_] = pop(id);
    }
  }

  void moveBetweenStacks(StackId from, StackId to) {
    push(to, pop(from));
    while (!isEmpty(from) && peek(from) == peek(to)) {
      push(to, pop(from));
    }
  }

  static bool validNumberMoves(int moves) {
    if (moves == 0) {
      return true;
    }
    if (moves % 2 == 0) {
      return false;
    }
    return validNumberMoves(moves / 2);
  }

  static int getHeight(int movesPlus1) {
    if (movesPlus1 == 1) {
      return 0;
    }
    return getHeight(movesPlus1 / 2) + 1;
  }

  bool endConMet(int endCon, int moves) {
    if (!validNumberMoves(moves)) {
      return false;
    }
    switch (endCon) {
    case 1:
      return stack2_.empty() || target_ <= stack2_.back();
    case 2:
      return moves == targetMoves_;
    case 3:
      return stack2_.empty();
    default:
      throw std::runtime_error("unknown end condition");
    }
  }

  int hanoi(int startStack, bool goRight, int endCon) {
    int moves = 0;
    int minPoleLoc = startStack;

    if (!endConMet(endCon, moves)) {
      moves++;
      switch (minPoleLoc) {
      case 1:
        if (goRight) {
          moveFromMain(StackId::Two, true);
          minPoleLoc = 2;
        } else {
          moveFromMain(StackId::Three, true);
          minPoleLoc = 3;
        }
        break;
      case 2:
        if (goRight) {
          moveBetweenStacks(StackId::Two, StackId::Three);
          minPoleLoc = 3;
        } else {
          moveToMain(StackId::Two);
          minPoleLoc = 1;
        }
        break;
      default:
        if (goRight) {
          moveToMain(StackId::Three);
          minPoleLoc = 1;
        } else {
          moveBetweenStacks(StackId::Three, StackId::Two);
          minPoleLoc = 2;
        }
        break;
      }
    }

    while (!endConMet(endCon, moves)) {
      moves += 2;
      switch (minPoleLoc) {
      case 1:
        if (!stack2_.empty() &&
            (stack3_.empty() || stack2_.back() < stack3_.back())) {
          moveBetweenStacks(StackId::Two, StackId::Three);
        } else {
          moveBetweenStacks(StackId::Three, StackId::Two);
        }
        if (goRight) {
          moveFromMain(StackId::Two, true);
          minPoleLoc = 2;
        } else {
          moveFromMain(StackId::Three, true);
          minPoleLoc = 3;
        }
        break;
      case 2:
        if (stack3_.empty() ||
            (sp_ < unsorted_ && arr_[sp_] < stack3_.back())) {
          moveFromMain(StackId::Three, true);
        } else {
          moveToMain(StackId::Three);
        }
        if (goRight) {
          moveBetweenStacks(StackId::Two, StackId::Three);
          minPoleLoc = 3;
        } else {
          moveToMain(StackId::Two);
          minPoleLoc = 1;
        }
        break;
      default:
        if (stack2_.empty() ||
            (sp_ < unsorted_ && arr_[sp_] < stack2_.back())) {
          moveFromMain(StackId::Two, true);
        } else {
          moveToMain(StackId::Two);
        }
        if (goRight) {
          moveToMain(StackId::Three);
          minPoleLoc = 1;
        } else {
          moveBetweenStacks(StackId::Three, StackId::Two);
          minPoleLoc = 2;
        }
        break;
      }
    }

    return moves;
  }

  void removeFromMainStack() {
    target_ = arr_[sp_];
    int moves = hanoi(2, true, 1);
    int height = getHeight(moves + 1);
    targetMoves_ = moves;
    bool evenHeight = height % 2 == 0;

    if (evenHeight) {
      hanoi(1, true, 2);
    }
    unsorted_ += moveFromMain(StackId::Two, false);
    hanoi(3, evenHeight, 2);
  }

  void returnToMainStack() {
    int moves = hanoi(2, true, 3);
    int height = getHeight(moves + 1);
    if (height % 2 == 1) {
      targetMoves_ = moves;
      hanoi(3, true, 2);
    }
  }
};

void sort(int arr[], int n) {
  if (n <= 1) {
    return;
  }
  HanoiSorter sorter(arr, n);
  sorter.run();
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
