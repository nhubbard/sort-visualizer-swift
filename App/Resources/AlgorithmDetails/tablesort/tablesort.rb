def stable_comp(arr, table, a, b)
  ta = table[a]
  tb = table[b]
  return true if arr[ta] > arr[tb]
  return table[a] > table[b] if arr[ta] == arr[tb]
  false
end

def median_of_three(arr, table, a, b)
  m = a + (b - 1 - a) / 2
  table[a], table[m] = table[m], table[a] if stable_comp(arr, table, a, m)
  if stable_comp(arr, table, m, b - 1)
    table[m], table[b - 1] = table[b - 1], table[m]
    return if stable_comp(arr, table, a, m)
  end
  table[a], table[m] = table[m], table[a]
end

def partition(arr, table, a, b, p)
  i = a - 1
  j = b
  loop do
    loop do
      i += 1
      break unless i < j && !stable_comp(arr, table, i, p)
    end
    loop do
      j -= 1
      break unless j >= i && stable_comp(arr, table, j, p)
    end
    if i < j
      table[i], table[j] = table[j], table[i]
    else
      return j
    end
  end
end

def quick_sort(arr, table, a, b)
  if b - a < 3
    if b - a == 2 && stable_comp(arr, table, a, a + 1)
      table[a], table[a + 1] = table[a + 1], table[a]
    end
    return
  end
  median_of_three(arr, table, a, b)
  p = partition(arr, table, a + 1, b, a)
  table[a], table[p] = table[p], table[a]
  quick_sort(arr, table, a, p)
  quick_sort(arr, table, p + 1, b)
end

def sort(arr)
  n = arr.length
  table = (0...n).to_a
  quick_sort(arr, table, 0, n)
  (0...n).each do |i|
    next if table[i] == i

    t = arr[i]
    j = i
    nxt = table[i]
    loop do
      arr[j] = arr[nxt]
      table[j] = j
      j = nxt
      nxt = table[nxt]
      break unless nxt != i
    end
    arr[j] = t
    table[j] = j
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
