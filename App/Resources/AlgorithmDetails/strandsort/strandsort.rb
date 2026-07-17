def merge_to(arr, sub_list, a, m, b)
  i = 0
  s = m - a
  while i < s && m < b
    if sub_list[i] < arr[m]
      arr[a] = sub_list[i]
      a += 1
      i += 1
    else
      arr[a] = arr[m]
      a += 1
      m += 1
    end
  end
  while i < s
    arr[a] = sub_list[i]
    a += 1
    i += 1
  end
end

def sort(arr)
  n = arr.length
  return if n < 2
  sub_list = Array.new(n, 0)
  j = n
  k = j
  while j > 0
    sub_list[0] = arr[0]
    k -= 1
    i = 0
    p = 0
    m = 1
    while m < j
      if arr[m] >= sub_list[i]
        i += 1
        sub_list[i] = arr[m]
        k -= 1
      else
        arr[p] = arr[m]
        p += 1
      end
      m += 1
    end
    merge_to(arr, sub_list, k, j, n)
    j = k
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
