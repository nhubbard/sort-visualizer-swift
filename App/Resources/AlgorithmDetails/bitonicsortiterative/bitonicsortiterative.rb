def sort(arr)
  n = arr.length
  k = 2
  while k < 2 * n
    m = ((n + k - 1) / k).odd?
    j = k / 2
    while j > 0
      i = 0
      while i < n
        l = i ^ j
        if l > i && l < n
          ascending = ((i & k) == 0) == m
          if (ascending && arr[i] > arr[l]) || (!ascending && arr[i] < arr[l])
            arr[i], arr[l] = arr[l], arr[i]
          end
        end
        i += 1
      end
      j /= 2
    end
    k *= 2
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
