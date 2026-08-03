#include <climits>
#include <cstdio>
#include <vector>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

constexpr int kEmpty = INT_MIN;

void sort(int arr[], int n) {
  if (n <= 1) {
    return;
  }

  int capacity = 0;
  std::vector<int> slots;
  // Physical `slots` index of each placed element, ascending by both position
  // and value.
  std::vector<int> positions;

  auto rebalance = [&]() {
    int count = static_cast<int>(positions.size());
    int newCapacity = count * 2 > 2 ? count * 2 : 2;
    std::vector<int> newSlots(static_cast<size_t>(newCapacity), kEmpty);
    std::vector<int> newPositions;
    for (int i = 0; i < count; i++) {
      int pos = positions[static_cast<size_t>(i)];
      int newPos = i * 2;
      newSlots[static_cast<size_t>(newPos)] = slots[static_cast<size_t>(pos)];
      newPositions.push_back(newPos);
    }
    slots = std::move(newSlots);
    positions = std::move(newPositions);
    capacity = newCapacity;
  };

  auto insert = [&](int value) {
    if (static_cast<int>(positions.size()) == capacity) {
      rebalance();
    }

    // Upper-bound binary search: first slot whose value is strictly greater
    // than `value`.
    int lo = 0;
    int hi = static_cast<int>(positions.size());
    while (lo < hi) {
      int mid = (lo + hi) / 2;
      if (slots[static_cast<size_t>(positions[static_cast<size_t>(mid)])] >
          value) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    int k = lo;
    int targetPos = k == 0 ? 0 : positions[static_cast<size_t>(k - 1)] + 1;

    if (!(targetPos == capacity ||
          slots[static_cast<size_t>(targetPos)] != kEmpty)) {
      slots[static_cast<size_t>(targetPos)] = value;
      positions.insert(positions.begin() + k, targetPos);
      return;
    }

    // Either targetPos is already occupied, or targetPos == capacity (new
    // maximum, no room left of the structure's end). Search BOTH directions for
    // the nearest gap and shift whichever side is closer.
    int leftGap = targetPos - 1;
    while (leftGap >= 0 && slots[static_cast<size_t>(leftGap)] != kEmpty) {
      leftGap--;
    }
    int rightGap = targetPos;
    while (rightGap < capacity &&
           slots[static_cast<size_t>(rightGap)] != kEmpty) {
      rightGap++;
    }
    int leftDistance = leftGap >= 0 ? targetPos - leftGap : INT_MAX;
    int rightDistance = rightGap < capacity ? rightGap - targetPos : INT_MAX;

    if (rightDistance <= leftDistance) {
      int i = rightGap;
      while (i > targetPos) {
        slots[static_cast<size_t>(i)] = slots[static_cast<size_t>(i - 1)];
        i--;
      }
      for (int idx = k; idx < k + (rightGap - targetPos); idx++) {
        positions[static_cast<size_t>(idx)]++;
      }
      slots[static_cast<size_t>(targetPos)] = value;
      positions.insert(positions.begin() + k, targetPos);
    } else {
      int shiftCount = (targetPos - 1) - leftGap;
      int i = leftGap;
      while (i < targetPos - 1) {
        slots[static_cast<size_t>(i)] = slots[static_cast<size_t>(i + 1)];
        i++;
      }
      for (int idx = k - shiftCount; idx < k; idx++) {
        positions[static_cast<size_t>(idx)]--;
      }
      slots[static_cast<size_t>(targetPos - 1)] = value;
      positions.insert(positions.begin() + k, targetPos - 1);
    }
  };

  for (int i = 0; i < n; i++) {
    insert(arr[i]);
  }

  for (int i = 0; i < n; i++) {
    arr[i] = slots[static_cast<size_t>(positions[static_cast<size_t>(i)])];
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
