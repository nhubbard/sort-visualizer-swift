def sort(arr)
  n = arr.length()
  p = 1
  while p < n
    k = p
    while k > 0
      j = k % p
      while j + k < n
        (0...k).each do |i|
          if (i + j) / (p + p) == (i + j + k) / (p + p)
            if i + j + k < n
              if arr[i + j] > arr[i + j + k]
                arr[i + j], arr[i + j + k] = arr[i + j + k], arr[i + j]
              end
            end
          end
        end
        j += k + k
      end
      k /= 2
    end
    p += p
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array