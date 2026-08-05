RADIX_BASE = 10

# Extracts the digit at `place` (0 = ones place) from `value`, in RADIX_BASE.
def digit_at(value, place)
  divisor = RADIX_BASE**place
  (value / divisor) % RADIX_BASE
end

# Swaps the two equal-length adjacent blocks [a, a+len) and [b, b+len).
def multi_swap(arr, a, b, length)
  (0...length).each do |i|
    arr[a + i], arr[b + i] = arr[b + i], arr[a + i]
  end
end

# Rotates the adjacent blocks [a, m) and [m, b) into swapped order in place,
# using only block-swaps -- no auxiliary buffer.
def rotate_block(arr, a, m, b)
  left = m - a
  right = b - m
  while left > 0 && right > 0
    if right < left
      multi_swap(arr, m - right, m, right)
      b -= right
      m -= right
      left -= right
    else
      multi_swap(arr, a, m, left)
      a += left
      m += left
      right -= left
    end
  end
end

# Finds the leftmost index in [a, b) whose digit-`place` value is >= d,
# assuming [a, b) is already sorted by that digit.
def digit_lower_bound(arr, a, b, d, place)
  while a < b
    mid = (a + b) / 2
    if digit_at(arr[mid], place) >= d
      b = mid
    else
      a = mid + 1
    end
  end
  a
end

# Merges the two adjacent digit-sorted runs [a, m) and [m, b), whose digit-`place`
# values are known to lie in [da, db), by rotating the below-threshold prefixes of
# both runs together and recursing into the two halves that produces.
def merge_by_digit(arr, a, m, b, da, db, place)
  return if b - a < 2 || db - da < 2

  dm = (da + db) / 2
  m1 = digit_lower_bound(arr, a, m, dm, place)
  m2 = digit_lower_bound(arr, m, b, dm, place)
  rotate_block(arr, m1, m, m2)
  new_m = m1 + (m2 - m)
  merge_by_digit(arr, new_m, m2, b, dm, db, place)
  merge_by_digit(arr, a, m1, new_m, da, dm, place)
end

# Sorts [a, b) by digit-`place` alone via ordinary merge-sort recursion on the
# index range, merging with merge_by_digit instead of a linear merge.
def digit_merge_sort(arr, a, b, place)
  return if b - a < 2

  mid = (a + b) / 2
  digit_merge_sort(arr, a, mid, place)
  digit_merge_sort(arr, mid, b, place)
  merge_by_digit(arr, a, mid, b, 0, RADIX_BASE, place)
end

def sort(arr)
  n = arr.length
  return if n < 2

  max_value = arr.max
  max_place = 0
  probe = RADIX_BASE
  while probe <= max_value
    max_place += 1
    probe *= RADIX_BASE
  end
  (0..max_place).each do |place|
    digit_merge_sort(arr, 0, n, place)
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
