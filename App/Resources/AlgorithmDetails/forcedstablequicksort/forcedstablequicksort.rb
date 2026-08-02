def stable_comp(arr, key, a, b)
  return true if arr[a] > arr[b]
  return key[a] > key[b] if arr[a] == arr[b]

  false
end

def stable_swap(arr, key, a, b)
  arr[a], arr[b] = arr[b], arr[a]
  key[a], key[b] = key[b], key[a]
end

def median_of_three(arr, key, a, b)
  m = a + (b - 1 - a) / 2
  stable_swap(arr, key, a, m) if stable_comp(arr, key, a, m)
  if stable_comp(arr, key, m, b - 1)
    stable_swap(arr, key, m, b - 1)
    return if stable_comp(arr, key, a, m)
  end
  stable_swap(arr, key, a, m)
end

def partition(arr, key, a, b, p)
  i = a - 1
  j = b
  loop do
    begin
      i += 1
    end while i < j && !stable_comp(arr, key, i, p)
    begin
      j -= 1
    end while j >= i && stable_comp(arr, key, j, p)
    if i < j
      stable_swap(arr, key, i, j)
    else
      return j
    end
  end
end

def quick_sort(arr, key, a, b)
  if b - a < 3
    stable_swap(arr, key, a, a + 1) if b - a == 2 && stable_comp(arr, key, a, a + 1)
    return
  end
  median_of_three(arr, key, a, b)
  p = partition(arr, key, a + 1, b, a)
  stable_swap(arr, key, a, p)
  quick_sort(arr, key, a, p)
  quick_sort(arr, key, p + 1, b)
end

def sort(arr)
  n = arr.length
  key = (0...n).to_a
  quick_sort(arr, key, 0, n)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
