def min_run_length(n)
  r = 0
  while n >= 64
    r |= n & 1
    n >>= 1
  end
  n + r
end

def cocktail_shaker_sort(array, start, last)
  length = last - start
  return if length <= 1
  i = 0
  while i < length / 2
    is_sorted = true
    j = i
    while j < length - i - 1
      if array[start + j] > array[start + j + 1]
        array[start + j], array[start + j + 1] = array[start + j + 1], array[start + j]
        is_sorted = false
      end
      j += 1
    end
    j = length - i - 1
    while j > i
      if array[start + j - 1] > array[start + j]
        array[start + j - 1], array[start + j] = array[start + j], array[start + j - 1]
        is_sorted = false
      end
      j -= 1
    end
    break if is_sorted
    i += 1
  end
end

def merge(array, start, mid, last)
  left = array[start...mid]
  right = array[mid...last]
  i = 0
  j = 0
  k = start
  while i < left.length && j < right.length
    if left[i] <= right[j]
      array[k] = left[i]
      i += 1
    else
      array[k] = right[j]
      j += 1
    end
    k += 1
  end
  while i < left.length
    array[k] = left[i]
    i += 1
    k += 1
  end
  while j < right.length
    array[k] = right[j]
    j += 1
    k += 1
  end
end

def cocktail_merge_sort(array)
  n = array.length
  return if n <= 1
  min_run = min_run_length(n)
  if n == min_run
    cocktail_shaker_sort(array, 0, n)
    return
  end
  i = 0
  while i <= n - min_run
    cocktail_shaker_sort(array, i, i + min_run)
    i += min_run
  end
  cocktail_shaker_sort(array, i, n) if i < n
  width = min_run
  while width < n
    i = 0
    while i < n
      mid = [i + width, n].min
      last = [i + 2 * width, n].min
      merge(array, i, mid, last) if mid < last
      i += 2 * width
    end
    width *= 2
  end
end

def sort(array)
  cocktail_merge_sort(array)
  return array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
