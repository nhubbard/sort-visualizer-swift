INSERT_SORT_THRESHOLD = 24
NINTHER_THRESHOLD = 128
PARTIAL_INSERT_SORT_LIMIT = 8
BLOCK_SIZE = 64
CACHELINE_SIZE = 64

def pdq_log(n)
  log = 0
  loop do
    n >>= 1
    break if n == 0
    log += 1
  end
  log
end

def trunc_div(a, b)
  # Integer division truncated toward zero. Ruby's `/` floors toward negative infinity for
  # negative operands (like Python), but the pivot-position arithmetic below can go
  # negative, so plain `/` would silently disagree with C/Java/Swift/etc. semantics there.
  q = a.abs / b.abs
  (a < 0) != (b < 0) ? -q : q
end

def insert_sort(arr, begin_, end_)
  ((begin_ + 1)...end_).each do |cur|
    if arr[cur] < arr[cur - 1]
      tmp = arr[cur]
      sift = cur
      sift_minus_one = cur - 1
      loop do
        arr[sift] = arr[sift_minus_one]
        sift -= 1
        sift_minus_one -= 1
        break if sift == begin_ || !(tmp < arr[sift_minus_one])
      end
      arr[sift] = tmp
    end
  end
end

def unguard_insert_sort(arr, begin_, end_)
  ((begin_ + 1)...end_).each do |cur|
    if arr[cur] < arr[cur - 1]
      tmp = arr[cur]
      sift = cur
      sift_minus_one = cur - 1
      loop do
        arr[sift] = arr[sift_minus_one]
        sift -= 1
        sift_minus_one -= 1
        break if !(tmp < arr[sift_minus_one])
      end
      arr[sift] = tmp
    end
  end
end

def partial_insert_sort(arr, begin_, end_)
  limit = 0
  ((begin_ + 1)...end_).each do |cur|
    return false if limit > PARTIAL_INSERT_SORT_LIMIT
    if arr[cur] < arr[cur - 1]
      tmp = arr[cur]
      sift = cur
      sift_minus_one = cur - 1
      loop do
        arr[sift] = arr[sift_minus_one]
        sift -= 1
        sift_minus_one -= 1
        break if sift == begin_ || !(tmp < arr[sift_minus_one])
      end
      arr[sift] = tmp
      limit += cur - sift
    end
  end
  true
end

def sort_two(arr, a, b)
  arr[a], arr[b] = arr[b], arr[a] if arr[b] < arr[a]
end

def sort_three(arr, a, b, c)
  sort_two(arr, a, b)
  sort_two(arr, b, c)
  sort_two(arr, a, b)
end

def swap_offsets(arr, first, last, left_offsets, left_pos, right_offsets, right_pos, num, use_swaps)
  if use_swaps
    (0...num).each do |i|
      li = first + left_offsets[left_pos + i]
      ri = last - right_offsets[right_pos + i]
      arr[li], arr[ri] = arr[ri], arr[li]
    end
  elsif num > 0
    left = first + left_offsets[left_pos]
    right = last - right_offsets[right_pos]
    tmp = arr[left]
    arr[left] = arr[right]
    (1...num).each do |i|
      left = first + left_offsets[left_pos + i]
      arr[right] = arr[left]
      right = last - right_offsets[right_pos + i]
      arr[left] = arr[right]
    end
    arr[right] = tmp
  end
end

def part_right_branchless(arr, begin_, end_, left_offsets, right_offsets)
  pivot = arr[begin_]
  first = begin_
  last = end_

  first += 1
  first += 1 while arr[first] < pivot

  if first - 1 == begin_
    last -= 1
    while first < last && !(arr[last] < pivot)
      last -= 1
    end
  else
    last -= 1
    last -= 1 while !(arr[last] < pivot)
  end

  already_parted = first >= last
  unless already_parted
    arr[first], arr[last] = arr[last], arr[first]
    first += 1
  end

  left_num = 0
  right_num = 0
  left_start = 0
  right_start = 0

  while last - first > 2 * BLOCK_SIZE
    if left_num == 0
      left_start = 0
      it = first
      (0...BLOCK_SIZE).each do |i|
        left_offsets[left_num] = i
        left_num += 1 unless arr[it] < pivot
        it += 1
      end
    end
    if right_num == 0
      right_start = 0
      it = last
      (0...BLOCK_SIZE).each do |i|
        it -= 1
        right_offsets[right_num] = i + 1
        right_num += 1 if arr[it] < pivot
      end
    end

    num = [left_num, right_num].min
    swap_offsets(arr, first, last, left_offsets, left_start, right_offsets, right_start, num, left_num == right_num)
    left_num -= num
    right_num -= num
    left_start += num
    right_start += num
    first += BLOCK_SIZE if left_num == 0
    last -= BLOCK_SIZE if right_num == 0
  end

  left_size = 0
  right_size = 0
  unknown_left = (last - first) - ((right_num != 0 || left_num != 0) ? BLOCK_SIZE : 0)
  if right_num != 0
    left_size = unknown_left
    right_size = BLOCK_SIZE
  elsif left_num != 0
    left_size = BLOCK_SIZE
    right_size = unknown_left
  else
    left_size = trunc_div(unknown_left, 2)
    right_size = unknown_left - left_size
  end

  if unknown_left != 0 && left_num == 0
    left_start = 0
    it = first
    (0...left_size).each do |i|
      left_offsets[left_num] = i
      left_num += 1 unless arr[it] < pivot
      it += 1
    end
  end

  if unknown_left != 0 && right_num == 0
    right_start = 0
    it = last
    (0...right_size).each do |i|
      it -= 1
      right_offsets[right_num] = i + 1
      right_num += 1 if arr[it] < pivot
    end
  end

  num = [left_num, right_num].min
  swap_offsets(arr, first, last, left_offsets, left_start, right_offsets, right_start, num, left_num == right_num)
  left_num -= num
  right_num -= num
  left_start += num
  right_start += num
  first += left_size if left_num == 0
  last -= right_size if right_num == 0

  left_offsets_pos = 0
  right_offsets_pos = 0

  if left_num != 0
    left_offsets_pos += left_start
    while left_num != 0
      left_num -= 1
      last -= 1
      src = first + left_offsets[left_offsets_pos + left_num]
      arr[src], arr[last] = arr[last], arr[src]
    end
    first = last
  end

  if right_num != 0
    right_offsets_pos += right_start
    while right_num != 0
      right_num -= 1
      src = last - right_offsets[right_offsets_pos + right_num]
      arr[src], arr[first] = arr[first], arr[src]
      first += 1
    end
    last = first
  end

  pivot_pos = first - 1
  arr[begin_] = arr[pivot_pos]
  arr[pivot_pos] = pivot

  [pivot_pos, already_parted]
end

def part_left(arr, begin_, end_)
  pivot = arr[begin_]
  first = begin_
  last = end_

  last -= 1
  last -= 1 while pivot < arr[last]

  if last + 1 == end_
    first += 1
    while first < last && !(pivot < arr[first])
      first += 1
    end
  else
    first += 1
    first += 1 while !(pivot < arr[first])
  end

  while first < last
    arr[first], arr[last] = arr[last], arr[first]
    last -= 1
    last -= 1 while pivot < arr[last]
    first += 1
    first += 1 while !(pivot < arr[first])
  end

  pivot_pos = last
  arr[begin_] = arr[pivot_pos]
  arr[pivot_pos] = pivot
  pivot_pos
end

def sift_down(arr, begin_, root, size)
  loop do
    child = 2 * root + 1
    break if child >= size
    child += 1 if child + 1 < size && arr[begin_ + child] < arr[begin_ + child + 1]
    if arr[begin_ + root] < arr[begin_ + child]
      arr[begin_ + root], arr[begin_ + child] = arr[begin_ + child], arr[begin_ + root]
      root = child
    else
      break
    end
  end
end

def heap_sort(arr, begin_, end_)
  n = end_ - begin_
  (n / 2 - 1).downto(0) { |i| sift_down(arr, begin_, i, n) }
  (n - 1).downto(1) do |i|
    arr[begin_], arr[begin_ + i] = arr[begin_ + i], arr[begin_]
    sift_down(arr, begin_, 0, i)
  end
end

def pdq_loop(arr, begin_, end_, bad_allowed, left_offsets, right_offsets)
  leftmost = true
  loop do
    size = end_ - begin_

    if size < INSERT_SORT_THRESHOLD
      if leftmost
        insert_sort(arr, begin_, end_)
      else
        unguard_insert_sort(arr, begin_, end_)
      end
      return
    end

    half_size = size / 2
    if size > NINTHER_THRESHOLD
      sort_three(arr, begin_, begin_ + half_size, end_ - 1)
      sort_three(arr, begin_ + 1, begin_ + half_size - 1, end_ - 2)
      sort_three(arr, begin_ + 2, begin_ + half_size + 1, end_ - 3)
      sort_three(arr, begin_ + half_size - 1, begin_ + half_size, begin_ + half_size + 1)
      arr[begin_], arr[begin_ + half_size] = arr[begin_ + half_size], arr[begin_]
    else
      sort_three(arr, begin_ + half_size, begin_, end_ - 1)
    end

    if !leftmost && !(arr[begin_ - 1] < arr[begin_])
      begin_ = part_left(arr, begin_, end_) + 1
      next
    end

    pivot_pos, already_parted = part_right_branchless(arr, begin_, end_, left_offsets, right_offsets)

    left_size = pivot_pos - begin_
    right_size = end_ - (pivot_pos + 1)
    high_unbalance = left_size < size / 8 || right_size < size / 8

    if high_unbalance
      bad_allowed -= 1
      if bad_allowed == 0
        heap_sort(arr, begin_, end_)
        return
      end

      if left_size >= INSERT_SORT_THRESHOLD
        arr[begin_], arr[begin_ + left_size / 4] = arr[begin_ + left_size / 4], arr[begin_]
        arr[pivot_pos - 1], arr[pivot_pos - left_size / 4] = arr[pivot_pos - left_size / 4], arr[pivot_pos - 1]
        if left_size > NINTHER_THRESHOLD
          arr[begin_ + 1], arr[begin_ + (left_size / 4 + 1)] = arr[begin_ + (left_size / 4 + 1)], arr[begin_ + 1]
          arr[begin_ + 2], arr[begin_ + (left_size / 4 + 2)] = arr[begin_ + (left_size / 4 + 2)], arr[begin_ + 2]
          arr[pivot_pos - 2], arr[pivot_pos - (left_size / 4 + 1)] = arr[pivot_pos - (left_size / 4 + 1)], arr[pivot_pos - 2]
          arr[pivot_pos - 3], arr[pivot_pos - (left_size / 4 + 2)] = arr[pivot_pos - (left_size / 4 + 2)], arr[pivot_pos - 3]
        end
      end

      if right_size >= INSERT_SORT_THRESHOLD
        arr[pivot_pos + 1], arr[pivot_pos + (1 + right_size / 4)] = arr[pivot_pos + (1 + right_size / 4)], arr[pivot_pos + 1]
        arr[end_ - 1], arr[end_ - right_size / 4] = arr[end_ - right_size / 4], arr[end_ - 1]
        if right_size > NINTHER_THRESHOLD
          arr[pivot_pos + 2], arr[pivot_pos + (2 + right_size / 4)] = arr[pivot_pos + (2 + right_size / 4)], arr[pivot_pos + 2]
          arr[pivot_pos + 3], arr[pivot_pos + (3 + right_size / 4)] = arr[pivot_pos + (3 + right_size / 4)], arr[pivot_pos + 3]
          arr[end_ - 2], arr[end_ - (1 + right_size / 4)] = arr[end_ - (1 + right_size / 4)], arr[end_ - 2]
          arr[end_ - 3], arr[end_ - (2 + right_size / 4)] = arr[end_ - (2 + right_size / 4)], arr[end_ - 3]
        end
      end
    else
      if already_parted && partial_insert_sort(arr, begin_, pivot_pos) && partial_insert_sort(arr, pivot_pos + 1, end_)
        return
      end
    end

    pdq_loop(arr, begin_, pivot_pos, bad_allowed, left_offsets, right_offsets)
    begin_ = pivot_pos + 1
    leftmost = false
  end
end

def sort(arr)
  n = arr.length
  return if n < 2
  left_offsets = Array.new(BLOCK_SIZE + CACHELINE_SIZE, 0)
  right_offsets = Array.new(BLOCK_SIZE + CACHELINE_SIZE, 0)
  pdq_loop(arr, 0, n, pdq_log(n), left_offsets, right_offsets)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
