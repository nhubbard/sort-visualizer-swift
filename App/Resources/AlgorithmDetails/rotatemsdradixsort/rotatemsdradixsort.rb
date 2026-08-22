def int_pow(base, exponent)
  result = 1
  exponent.times { result *= base }
  result
end

def get_digit(value, place, base)
  (value / int_pow(base, place)) % base
end

def multi_swap(arr, a, b, length)
  length.times do |i|
    arr[a + i], arr[b + i] = arr[b + i], arr[a + i]
  end
end

def rotate(arr, a, m, b)
  l = m - a
  r = b - m
  while l > 0 && r > 0
    if r < l
      multi_swap(arr, m - r, m, r)
      b -= r
      m -= r
      l -= r
    else
      multi_swap(arr, a, m, l)
      a += l
      m += l
      r -= l
    end
  end
end

def bin_search_digit(arr, a, b, d, place, base)
  while a < b
    mid = (a + b) / 2
    if get_digit(arr[mid], place, base) >= d
      b = mid
    else
      a = mid + 1
    end
  end
  a
end

def merge_digit(arr, a, m, b, da, db, place, base)
  return if b - a < 2 || db - da < 2

  dm = (da + db) / 2
  m1 = bin_search_digit(arr, a, m, dm, place, base)
  m2 = bin_search_digit(arr, m, b, dm, place, base)
  rotate(arr, m1, m, m2)
  new_m = m1 + (m2 - m)
  merge_digit(arr, new_m, m2, b, dm, db, place, base)
  merge_digit(arr, a, m1, new_m, da, dm, place, base)
end

def merge_sort_digit(arr, a, b, place, base)
  return if b - a < 2

  mid = (a + b) / 2
  merge_sort_digit(arr, a, mid, place, base)
  merge_sort_digit(arr, mid, b, place, base)
  merge_digit(arr, a, mid, b, 0, base, place, base)
end

# Digit-sorts arr[a...b] in place by +place+ using rotation instead of
# counting buckets, then recurses into every resulting digit bucket one
# place lower -- an ordinary MSD radix sort built entirely out of the LSD
# variant's rotate/binary-search machinery.
def msd_rotate_sort(arr, a, b, place, base)
  return if b - a < 2 || place.negative?

  merge_sort_digit(arr, a, b, place, base)
  start = a
  (0...base).each do |d|
    finish = bin_search_digit(arr, start, b, d + 1, place, base)
    msd_rotate_sort(arr, start, finish, place - 1, base)
    start = finish
  end
end

def sort(arr)
  return arr if arr.length <= 1

  base = 4
  max_value = arr.max
  highest_place = 0
  probe = base
  while probe <= max_value
    highest_place += 1
    probe *= base
  end
  msd_rotate_sort(arr, 0, arr.length, highest_place, base)
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
