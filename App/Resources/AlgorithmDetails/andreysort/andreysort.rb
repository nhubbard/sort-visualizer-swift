def swap(arr, i, j)
  arr[i], arr[j] = arr[j], arr[i]
end

# Base case below length 12: repeatedly swap the minimum of the remaining
# range to the front.
def selection_sort(arr, a_in, b_in)
  a = a_in
  b = b_in
  while b > 1
    k = 0
    (1...b).each do |i|
      k = i if arr[a + k] > arr[a + i]
    end
    swap(arr, a, a + k)
    a += 1
    b -= 1
  end
end

# Forward block-swap of l elements.
def aswap(arr, arr1_in, arr2_in, l_in)
  arr1 = arr1_in
  arr2 = arr2_in
  l = l_in
  while l > 0
    swap(arr, arr1, arr2)
    arr1 += 1
    arr2 += 1
    l -= 1
  end
end

# Merges the two runs ending at arr1/arr2 (lengths l1/l2), working backward
# from their high ends into the trailing buffer that starts right after
# arr2. Returns the count of unplaced left-run elements if the right run
# ran out first (0 otherwise).
def backmerge(arr, arr1_in, l1_in, arr2_in, l2_in)
  arr1 = arr1_in
  l1 = l1_in
  arr2 = arr2_in
  l2 = l2_in
  arr0 = arr2 + l1
  loop do
    if arr[arr1] > arr[arr2]
      swap(arr, arr1, arr0)
      arr1 -= 1
      arr0 -= 1
      l1 -= 1
      return 0 if l1 == 0
    else
      swap(arr, arr2, arr0)
      arr2 -= 1
      arr0 -= 1
      l2 -= 1
      break if l2 == 0
    end
  end
  res = l1
  loop do
    swap(arr, arr1, arr0)
    arr1 -= 1
    arr0 -= 1
    l1 -= 1
    break if l1 == 0
  end
  res
end

# Merges arr[a..a+l) (as l/r blocks of width r) using the buffer
# arr[a+l..a+l+r): selection-sorts the block leaders, then backmerges each
# selected block into place.
def rmerge(arr, a, l, r)
  i = 0
  while i < l
    q = i
    j = i + r
    while j < l
      q = j if arr[a + q] > arr[a + j]
      j += r
    end
    aswap(arr, a + i, a + q, r) if q != i
    if i != 0
      aswap(arr, a + l, a + i, r)
      backmerge(arr, a + (l + r - 1), r, a + (i - 1), r)
    end
    i += r
  end
end

# Computes the block size: roughly sqrt(len), rounded up to a power of two.
def rbnd(len_in)
  length = len_in / 2
  k = 0
  i = 1
  while i < length
    k += 1
    i *= 2
  end
  length /= k
  k = 1
  while k <= length
    k *= 2
  end
  k
end

def msort(arr, a, length)
  if length < 12
    selection_sort(arr, a, length)
    return
  end

  r = rbnd(length)
  lr = ((length / r) - 1) * r

  p = 2
  while p <= lr
    swap(arr, a + (p - 2), a + (p - 1)) if arr[a + (p - 2)] > arr[a + (p - 1)]
    if (p & 2) != 0
      p += 2
      next
    end

    aswap(arr, a + (p - 2), a + p, 2)

    m = length - p
    q = 2
    loop do
      q0 = 2 * q
      break if q0 > m || (p & q0) != 0

      backmerge(arr, a + (p - q - 1), q, a + (p + q - 1), q)
      q = q0
    end
    backmerge(arr, a + (p + q - 1), q, a + (p - q - 1), q)
    q1 = q
    q *= 2

    while (q & p).zero?
      q *= 2
      rmerge(arr, a + (p - q), q, q1)
    end

    p += 2
  end

  q1 = 0
  q = r
  while q < lr
    if (lr & q) != 0
      q1 += q
      rmerge(arr, a + (lr - q1), q1, r) if q1 != q
    end
    q *= 2
  end

  s0 = length - lr
  msort(arr, a + lr, s0)
  aswap(arr, a, a + lr, s0)
  s = s0 + backmerge(arr, a + (s0 - 1), s0, a + (lr - 1), lr - s0)
  msort(arr, a, s)
end

def sort(arr)
  n = arr.length
  msort(arr, 0, n)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
