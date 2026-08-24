INSERTION_THRESHOLD = 16

def insertion_sort(arr, lo, hi)
  ((lo + 1)...hi).each do |i|
    key = arr[i]
    j = i - 1
    while j >= lo && arr[j] > key
      arr[j + 1] = arr[j]
      j -= 1
    end
    arr[j + 1] = key
  end
end

# Returns whichever of a, b, c indexes the middle value of the three.
def median_of_three(arr, a, b, c)
  a, b = b, a if arr[a] > arr[b]
  if arr[b] > arr[c]
    b = c
    b = a if arr[a] > arr[b]
  end
  b
end

def flux_sort_range(arr, lo, hi, swap)
  n = hi - lo
  if n <= INSERTION_THRESHOLD
    insertion_sort(arr, lo, hi)
    return
  end

  mid = lo + (n / 2)
  pivot = arr[median_of_three(arr, lo, mid, hi - 1)]

  # Partition into arr (elements <= pivot) and swap (elements > pivot). Ties go to the
  # low side, which is what keeps the sort stable.
  low_write = lo
  high_write = 0
  (lo...hi).each do |read|
    value = arr[read]
    if value > pivot
      swap[high_write] = value
      high_write += 1
    else
      arr[low_write] = value
      low_write += 1
    end
  end

  (0...high_write).each { |i| arr[low_write + i] = swap[i] }

  if low_write == hi
    # Every element in range was <= pivot -- a run of duplicates around the pivot value
    # can cause this. There's no split to recurse into, so finish directly.
    insertion_sort(arr, lo, hi)
    return
  end

  flux_sort_range(arr, lo, low_write, swap)
  flux_sort_range(arr, low_write, hi, swap)
end

def sort(arr)
  n = arr.length
  return if n < 2
  swap = Array.new(n, 0)
  flux_sort_range(arr, 0, n, swap)
end

array = [
  55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97,
  15, 62, 34, 79, 21, 88, 5, 51, 66, 29, 44, 12
]
sort(array)
p array
