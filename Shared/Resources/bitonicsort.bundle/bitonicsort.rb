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
    
# Specific to bitonic sort: size must be power of 2.
items = [35, 74, 71, 72, 30, 53, 9, 0]
sort(items)
p items
