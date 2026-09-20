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
def shift(value, places, base)
  while places > 0
    value /= base
    places -= 1
  end
  value
end

def dist(arr, a, b, place, base)
  merge_sort_digit(arr, a, b, place, base)
  bin_search_digit(arr, a, b, 1, place, base)
end

def sort(arr)
  n = arr.length
  return arr if n <= 1
  base = 4
  max_value = arr.max
  q = 0
  probe = base
  while probe <= max_value
    q += 1
    probe *= base
  end
  m = 0
  i = 0
  b = n
  while i < n
    p = b - i < 1 ? i : dist(arr, i, b, q, base)
    if q == 0
      m += base
      t = m / base
      while t % base == 0
        t /= base
        q += 1
      end
      i = b
      b += 1 while b < n && shift(arr[b], q + 1, base) == shift(m, q + 1, base)
    else
      b = p
      q -= 1
    end
  end
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
