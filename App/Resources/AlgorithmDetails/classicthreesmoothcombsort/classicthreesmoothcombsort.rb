def is_3_smooth?(n)
  while n % 6 == 0
    n /= 6
  end
  while n % 3 == 0
    n /= 3
  end
  while n % 2 == 0
    n /= 2
  end
  n == 1
end

def sort(arr)
  n = arr.length
  (n - 1).downto(1) do |g|
    if is_3_smooth?(g)
      (g...n).each do |i|
        if arr[i - g] > arr[i]
          arr[i - g], arr[i] = arr[i], arr[i - g]
        end
      end
    end
  end
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
