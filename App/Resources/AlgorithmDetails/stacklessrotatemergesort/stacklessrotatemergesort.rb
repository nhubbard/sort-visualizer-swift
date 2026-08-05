def multi_swap(array, a, b, len)
  len.times do |i|
    array[a + i], array[b + i] = array[b + i], array[a + i]
  end
end

def rotate(array, a, m, b)
  l = m - a
  r = b - m
  while l > 0 && r > 0
    if r < l
      multi_swap(array, m - r, m, r)
      b -= r
      m -= r
      l -= r
    else
      multi_swap(array, a, m, l)
      a += l
      m += l
      r -= l
    end
  end
end

# Selects the c smallest combined elements of the two already-sorted runs
# array[a...m] and array[m...b] into the front half via a single rotation.
# Uses a merge-path (co-rank) binary search over whichever run is shorter:
# it looks for the split count r such that taking r elements from the tail
# of one run and (c - r) from the head of the other yields exactly the c
# smallest values in order, rather than searching for a value directly.
def partition_merge(array, a, m, b, c)
  len_a = m - a
  len_b = b - m
  return if len_a < 1 || len_b < 1

  if len_b < len_a
    cc = (len_a + len_b) - c
    r1 = [0, cc - len_a].max
    r2 = [cc, len_b].min
    while r1 < r2
      ml = r1 + (r2 - r1) / 2
      if array[m - (cc - ml)] > array[b - ml - 1]
        r2 = ml
      else
        r1 = ml + 1
      end
    end
    rotate(array, m - (cc - r1), m, b - r1)
  else
    r1 = [0, c - len_b].max
    r2 = [c, len_a].min
    while r1 < r2
      ml = r1 + (r2 - r1) / 2
      if array[a + ml] > array[m + (c - ml) - 1]
        r2 = ml
      else
        r1 = ml + 1
      end
    end
    rotate(array, a + r1, m, m + (c - r1))
  end
end

# Finds the first place inside array[a...b] where ascending order breaks,
# then partition-merges the sorted piece before it with the sorted piece
# after it. A no-op if array[a...b] is already one ascending run.
def rotate_merge(array, a, b, c)
  i = a + 1
  i += 1 while i < b && array[i - 1] <= array[i]
  partition_merge(array, a, i, b, c) if i < b
end

def rotate_partition_merge_sort(array, n)
  return if n < 2

  (1...n).step(2) do |i|
    array[i - 1], array[i] = array[i], array[i - 1] if array[i - 1] > array[i]
  end

  j = 2
  while j < n
    b1 = 0
    block_start = 0
    while block_start + j < n
      b1 = [block_start + 2 * j, n].min
      partition_merge(array, block_start, block_start + j, b1, j)
      block_start += 2 * j
    end

    k = j / 2
    while k > 1
      seam_start = 0
      while seam_start + k < b1
        seam_end = [seam_start + 2 * k, n].min
        rotate_merge(array, seam_start, seam_end, k)
        seam_start += 2 * k
      end
      k /= 2
    end

    (1...b1).step(2) do |m|
      array[m - 1], array[m] = array[m], array[m - 1] if array[m - 1] > array[m]
    end

    j *= 2
  end
end

def sort(arr)
  rotate_partition_merge_sort(arr, arr.length)
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
