def sort(arr)
  n = arr.length()
  k = 2
  while k <= n
    j = k / 2
    while j > 0
      i = 0
      while i < n
        l = i ^ j
        if l > i
          if (((i & k) == 0) && (arr[i] > arr[l]) ||
             (((i & k) != 0) && (arr[i] < arr[l])))
            arr[i], arr[l] = arr[l], arr[i]
          end
        end
        i = i + 1
      end
      j = j / 2
    end
    k = k * 2
  end
end
    
array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array