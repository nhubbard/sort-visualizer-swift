# Reverses arr[0..hi] in place. This "flip" is the only move the algorithm ever performs; there
# is no per-element shift anywhere.
def flip(arr, hi)
  lo = 0
  while lo < hi
    arr[lo], arr[hi] = arr[hi], arr[lo]
    lo += 1
    hi -= 1
  end
end

# Monobound binary search: locates the index within the ascending run arr[start...end] at which
# arr[value_index] belongs, using one comparison per halving instead of the usual two.
def search_ascending(arr, start, last, value_index)
  top = last - start
  while top > 1
    mid = top / 2
    last -= mid if arr[value_index] <= arr[last - mid]
    top -= mid
  end
  return last - 1 if arr[value_index] <= arr[last - 1]

  last
end

# Mirror image of search_ascending for a descending run arr[start...end].
def search_descending(arr, start, last, value_index)
  top = last - start
  while top > 1
    mid = top / 2
    start += mid if arr[start + mid] > arr[value_index]
    top -= mid
  end
  return start + 1 if arr[start] > arr[value_index]

  start
end

# Hand-sorts arr[0...n] for n <= 3 via a small decision tree. Returns true if the result runs
# ascending, false if it runs descending.
def sort_first_three(arr, n)
  return false if n < 2

  flip(arr, 1) if arr[0] > arr[1]
  if n > 2
    if arr[1] > arr[2]
      flip(arr, 2) unless arr[0] > arr[2]
      flip(arr, 1)
      return false
    end
    return true
  end
  true
end

def sort(arr)
  n = arr.length
  return arr if n < 2

  ascending = sort_first_three(arr, n)

  i = 3
  while i < n
    if ascending
      if arr[i - 1] <= arr[i]
        # Already fits; the ascending prefix already ends at or below the new element.
      elsif arr[0] > arr[i]
        # The new element is smaller than everything in the prefix -- one flip turns the whole
        # thing, including the new element, into a descending run.
        flip(arr, i - 1)
        ascending = false
      else
        idx = search_ascending(arr, 0, i, i)
        flip(arr, i)
        tail = i - idx
        flip(arr, tail)
        flip(arr, tail - 1)
        ascending = false
      end
    elsif arr[i - 1] > arr[i]
    # already fits
    elsif arr[0] <= arr[i]
      flip(arr, i - 1)
      ascending = true
    else
      idx = search_descending(arr, 0, i, i)
      flip(arr, i)
      tail = i - idx
      flip(arr, tail)
      flip(arr, tail - 1)
      ascending = true
    end
    i += 1
  end

  flip(arr, n - 1) unless ascending

  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
