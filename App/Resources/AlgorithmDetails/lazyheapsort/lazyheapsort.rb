def sort(arr)
  n = arr.length()

  max_to_front = lambda do |a, b|
    best = a
    i = a + 1
    while i < b
      if arr[i] > arr[best]
        best = i
      end
      i += 1
    end
    arr[best], arr[a] = arr[a], arr[best]
  end

  s = Math.sqrt(n - 1).to_i + 1

  i = 0
  while i < n
    max_to_front.call(i, [i + s, n].min)
    i += s
  end

  j = n
  while j > 0
    best = 0
    k = best + s
    while k < j
      if arr[k] >= arr[best]
        best = k
      end
      k += s
    end
    j -= 1
    arr[best], arr[j] = arr[j], arr[best]
    max_to_front.call(best, [best + s, j].min)
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
