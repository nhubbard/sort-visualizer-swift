def sort(arr):
    n = len(arr)
    if n <= 1:
        return

    empty = -(2**62)
    capacity = 0
    slots = []
    # Physical `slots` index of each placed element, ascending by both position and value.
    positions = []

    def rebalance():
        nonlocal slots, positions, capacity
        count = len(positions)
        new_capacity = max(2, count * 2)
        new_slots = [empty] * new_capacity
        new_positions = []
        for i, pos in enumerate(positions):
            new_pos = i * 2
            new_slots[new_pos] = slots[pos]
            new_positions.append(new_pos)
        slots = new_slots
        positions = new_positions
        capacity = new_capacity

    def insert(value):
        if len(positions) == capacity:
            rebalance()

        # Upper-bound binary search: first slot whose value is strictly greater than `value`.
        lo, hi = 0, len(positions)
        while lo < hi:
            mid = (lo + hi) // 2
            if slots[positions[mid]] > value:
                hi = mid
            else:
                lo = mid + 1
        k = lo
        target_pos = 0 if k == 0 else positions[k - 1] + 1

        if not (target_pos == capacity or slots[target_pos] != empty):
            slots[target_pos] = value
            positions.insert(k, target_pos)
            return

        # Either target_pos is already occupied, or target_pos == capacity (new maximum, no
        # room left of the structure's end). Search BOTH directions for the nearest gap and
        # shift whichever side is closer.
        left_gap = target_pos - 1
        while left_gap >= 0 and slots[left_gap] != empty:
            left_gap -= 1
        right_gap = target_pos
        while right_gap < capacity and slots[right_gap] != empty:
            right_gap += 1
        left_distance = target_pos - left_gap if left_gap >= 0 else float("inf")
        right_distance = (
            right_gap - target_pos if right_gap < capacity else float("inf")
        )

        if right_distance <= left_distance:
            i = right_gap
            while i > target_pos:
                slots[i] = slots[i - 1]
                i -= 1
            for idx in range(k, k + (right_gap - target_pos)):
                positions[idx] += 1
            slots[target_pos] = value
            positions.insert(k, target_pos)
        else:
            shift_count = (target_pos - 1) - left_gap
            i = left_gap
            while i < target_pos - 1:
                slots[i] = slots[i + 1]
                i += 1
            for idx in range(k - shift_count, k):
                positions[idx] -= 1
            slots[target_pos - 1] = value
            positions.insert(k, target_pos - 1)

    for v in arr:
        insert(v)

    result = [0] * n
    for i, pos in enumerate(positions):
        result[i] = slots[pos]
    arr[:] = result


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
