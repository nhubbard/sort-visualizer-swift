def sort(arr)
  n = arr.length()
  i = n / 2
  while i > 0
    j = i
    while j < n
      k = j - i
      while k >= 0
        if arr[k + i] >= arr[k] then
          break
        else
          arr[k], arr[k + i] = arr[k + i], arr[k]
        end
        k -= i
      end
      j += 1
    end
    i /= 2
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array