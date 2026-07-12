def flip(arr, end_index)
  start = 0
  e = end_index
  while start < e
    arr[start], arr[e] = arr[e], arr[start]
    start += 1
    e -= 1
  end
end

def sort(arr)
  n = arr.length()
  for i in (n - 1).downto(1)
    max = 0
    for j in (max + 1)..i
      if arr[j] > arr[max]
        max = j
      end
    end
    if max != i
      flip(arr, max)
      flip(arr, i)
      flip(arr, i - 1)
      flip(arr, max - 1)
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array