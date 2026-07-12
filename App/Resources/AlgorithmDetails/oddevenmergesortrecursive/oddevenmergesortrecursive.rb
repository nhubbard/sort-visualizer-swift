def odd_even_merge_compare(array, i, j)
  if array[i] > array[j]
    array[i], array[j] = array[j], array[i]
  end
end

# lo is the starting position, m2 is the halfway point, n is the length of
# the piece being merged, and r is the distance of the elements compared.
def odd_even_merge(array, lo, m2, n, r)
  m = r * 2
  if m < n
    if (n / r) % 2 != 0
      odd_even_merge(array, lo, (m2 + 1) / 2, n + r, m)     # even subsequence
      odd_even_merge(array, lo + r, m2 / 2, n - r, m)       # odd subsequence
    else
      odd_even_merge(array, lo, (m2 + 1) / 2, n, m)         # even subsequence
      odd_even_merge(array, lo + r, m2 / 2, n, m)           # odd subsequence
    end

    if m2 % 2 != 0
      i = lo
      while i + r < lo + n
        odd_even_merge_compare(array, i, i + r)
        i += m
      end
    else
      i = lo + r
      while i + r < lo + n
        odd_even_merge_compare(array, i, i + r)
        i += m
      end
    end
  else
    if n > r
      odd_even_merge_compare(array, lo, lo + r)
    end
  end
end

def odd_even_merge_sort(array, lo, n)
  if n > 1
    m = n / 2
    odd_even_merge_sort(array, lo, m)
    odd_even_merge_sort(array, lo + m, n - m)
    odd_even_merge(array, lo, m, n, 1)
  end
end

def sort(array)
  odd_even_merge_sort(array, 0, array.length())
  return array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
