def sort(arr)
  n = arr.length
  return if n <= 1

  empty = -(2**62)
  capacity = 0
  slots = []
  # Physical `slots` index of each placed element, ascending by both position and value.
  positions = []

  rebalance = lambda do
    count = positions.length
    new_capacity = [2, count * 2].max
    new_slots = Array.new(new_capacity, empty)
    new_positions = []
    positions.each_with_index do |pos, i|
      new_pos = i * 2
      new_slots[new_pos] = slots[pos]
      new_positions << new_pos
    end
    slots = new_slots
    positions = new_positions
    capacity = new_capacity
  end

  insert = lambda do |value|
    rebalance.call if positions.length == capacity

    # Upper-bound binary search: first slot whose value is strictly greater than `value`.
    lo = 0
    hi = positions.length
    while lo < hi
      mid = (lo + hi) / 2
      if slots[positions[mid]] > value
        hi = mid
      else
        lo = mid + 1
      end
    end
    k = lo
    target_pos = k.zero? ? 0 : positions[k - 1] + 1

    if !(target_pos == capacity || slots[target_pos] != empty)
      slots[target_pos] = value
      positions.insert(k, target_pos)
      next
    end

    # Either target_pos is already occupied, or target_pos == capacity (new maximum, no room
    # left of the structure's end). Search BOTH directions for the nearest gap and shift
    # whichever side is closer.
    left_gap = target_pos - 1
    while left_gap >= 0 && slots[left_gap] != empty
      left_gap -= 1
    end
    right_gap = target_pos
    while right_gap < capacity && slots[right_gap] != empty
      right_gap += 1
    end
    left_distance = (left_gap >= 0) ? target_pos - left_gap : Float::INFINITY
    right_distance = (right_gap < capacity) ? right_gap - target_pos : Float::INFINITY

    if right_distance <= left_distance
      i = right_gap
      while i > target_pos
        slots[i] = slots[i - 1]
        i -= 1
      end
      (k...(k + (right_gap - target_pos))).each { |idx| positions[idx] += 1 }
      slots[target_pos] = value
      positions.insert(k, target_pos)
    else
      shift_count = (target_pos - 1) - left_gap
      i = left_gap
      while i < target_pos - 1
        slots[i] = slots[i + 1]
        i += 1
      end
      ((k - shift_count)...k).each { |idx| positions[idx] -= 1 }
      slots[target_pos - 1] = value
      positions.insert(k, target_pos - 1)
    end
  end

  arr.each { |v| insert.call(v) }

  result = Array.new(n)
  positions.each_with_index { |pos, i| result[i] = slots[pos] }
  arr.replace(result)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
