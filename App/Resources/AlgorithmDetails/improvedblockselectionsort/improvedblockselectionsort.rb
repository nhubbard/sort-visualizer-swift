def block_root(n)
  i = 1
  while i * i < n
    i *= 2
  end
  i
end

def multi_swap(array, a, b, length)
  (0...length).each do |i|
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

def select_range(array, start, last, b_len)
  min_index = start
  a = start + b_len
  while a < last
    if array[a] < array[min_index]
      min_index = a
    elsif array[a] == array[min_index] && array[a + b_len - 1] < array[min_index + b_len - 1]
      min_index = a
    end
    a += b_len
  end
  min_index
end

def block_select(array, a, m, b, b_len)
  k = a
  j = m
  while k < m && array[k] <= array[m]
    k += b_len
  end
  return if k == m

  i = m
  multi_swap(array, k, j, b_len)
  k += b_len
  j += b_len

  while k < j && j < b
    if array[i] <= array[j]
      multi_swap(array, k, i, b_len) if k != i
      k += b_len
      i = select_range(array, [m, k].max, j, b_len)
    else
      i = j if i == k
      multi_swap(array, k, j, b_len) if k != j
      k += b_len
      j += b_len
    end
  end

  while k < j
    i = select_range(array, k, b, b_len)
    multi_swap(array, k, i, b_len) if k != i
    k += b_len
  end
end

def in_place_merge(array, a, m, b)
  i = a
  j = m
  while i < j && j < b
    if array[i] > array[j]
      k = j + 1
      while k < b && array[i] > array[k]
        k += 1
      end
      rotate(array, i, j, k)
      i += k - j
      j = k
    else
      i += 1
    end
  end
  i
end

def in_place_merge_bw(array, a, m, b)
  i = m - 1
  j = b - 1
  while j > i && i >= a
    if array[i] > array[j]
      k = i - 1
      while k >= a && array[k] > array[j]
        k -= 1
      end
      rotate(array, k + 1, i + 1, j + 1)
      j -= i - k
      i = k
    else
      j -= 1
    end
  end
end

def sort(array)
  n = array.length
  return if n <= 1
  j = 1
  while j < n
    b_len = block_root(j)
    run_length = j
    b = n - n % b_len

    while run_length > 16
      i = 0
      while i + j < b
        k = i
        while k + run_length < [i + 2 * j, b].min
          block_select(array, k, k + run_length, [k + 2 * run_length, b].min, b_len)
          k += run_length
        end
        i += 2 * j
      end
      run_length = b_len
      b_len = block_root(b_len)
    end

    i = 0
    while i + j < b
      k = i
      f = i
      while k + run_length < [i + 2 * j, b].min
        f = in_place_merge(array, f, k + run_length, [k + 2 * run_length, b].min)
        k += run_length
      end
      i += 2 * j
    end

    in_place_merge_bw(array, n - n % (2 * j), b, n)
    j *= 2
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
