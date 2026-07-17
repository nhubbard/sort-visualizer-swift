def insertion_sort(arr)
  n = arr.length
  i = 1
  while i < n
    key = arr[i]
    j = i - 1
    while j >= 0 && arr[j] > key
      arr[j + 1] = arr[j]
      j -= 1
    end
    arr[j + 1] = key
    i += 1
  end
end

def sort(arr)
  n = arr.length
  shrink = 1.3
  gap = n
  sorted = false
  threshold = [8, n / 32].min
  until sorted
    gap = (gap / shrink).to_i
    if gap <= 1
      sorted = true
      gap = 1
    end
    i = 0
    while i < n - gap
      if gap <= threshold
        insertion_sort(arr)
        return
      end
      sm = gap + i
      if arr[i] > arr[sm]
        arr[i], arr[sm] = arr[sm], arr[i]
        sorted = false
      end
      i += 1
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
