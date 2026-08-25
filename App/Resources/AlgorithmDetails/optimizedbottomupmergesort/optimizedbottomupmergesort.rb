BLOCK_SIZE = 16

def binary_insertion_sort(arr, lo, hi)
  ((lo + 1)...hi).each do |i|
    key = arr[i]
    left = lo
    right = i
    while left < right
      mid = (left + right) / 2
      if arr[mid] <= key
        left = mid + 1
      else
        right = mid
      end
    end
    j = i
    while j > left
      arr[j] = arr[j - 1]
      j -= 1
    end
    arr[left] = key
  end
end

def merge(src, dst, low, mid, high)
  i = low
  j = mid
  k = low
  while i < mid && j < high
    if src[i] <= src[j]
      dst[k] = src[i]
      i += 1
    else
      dst[k] = src[j]
      j += 1
    end
    k += 1
  end
  while i < mid
    dst[k] = src[i]
    i += 1
    k += 1
  end
  while j < high
    dst[k] = src[j]
    j += 1
    k += 1
  end
end

def sort(arr)
  n = arr.length
  if n < BLOCK_SIZE
    binary_insertion_sort(arr, 0, n)
    return
  end

  # Pre-pass: sort fixed-size blocks with binary insertion sort so the merge phase can
  # start from already-sorted runs instead of single elements.
  low = 0
  while low < n
    binary_insertion_sort(arr, low, [low + BLOCK_SIZE, n].min)
    low += BLOCK_SIZE
  end

  # Merge phase: ping-pong between arr and scratch, alternating direction every pass,
  # instead of always merging into scratch and copying the whole buffer back.
  scratch = Array.new(n, 0)
  src = arr
  dst = scratch
  width = BLOCK_SIZE
  passes = 0
  while width < n
    low = 0
    while low < n
      mid = [low + width, n].min
      high = [low + 2 * width, n].min
      if mid < high
        merge(src, dst, low, mid, high)
      else
        (low...mid).each { |i| dst[i] = src[i] }
      end
      low += 2 * width
    end
    src, dst = dst, src
    width *= 2
    passes += 1
  end

  # An even number of passes lands the sorted result back in arr on its own; an odd
  # number leaves it in scratch, needing this one explicit copy back.
  arr[0...n] = src[0...n] if passes.odd?
end

array = [
  81, 14, 3, 94, 35, 31, 28, 17, 94, 13, 86, 94, 69, 11, 75, 54,
  4, 3, 11, 27, 29, 64, 77, 3, 71, 25, 91, 83, 89, 69, 53, 28,
  57, 75, 35, 0, 97, 20, 89, 54
]
sort(array)
p array
