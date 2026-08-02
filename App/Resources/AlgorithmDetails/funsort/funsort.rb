def composite_less(arr, key, mid, i)
  return true if arr[mid] < arr[i]
  return key[mid] < key[i] if arr[mid] == arr[i]

  false
end

def binary_search(arr, key, n, i)
  start = 0
  fin = n - 1
  while start < fin
    mid = (start + fin) / 2
    if composite_less(arr, key, mid, i)
      start = mid + 1
    else
      fin = mid
    end
  end
  start
end

def sort(arr)
  n = arr.length
  key = (0...n).to_a

  (1...n).each do |i|
    done = false
    until done
      pos = binary_search(arr, key, n, i)
      if pos == i
        done = true
      elsif i < pos - 1
        arr[i], arr[pos - 1] = arr[pos - 1], arr[i]
        key[i], key[pos - 1] = key[pos - 1], key[i]
      else
        arr[i], arr[pos] = arr[pos], arr[i]
        key[i], key[pos] = key[pos], key[i]
      end
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
