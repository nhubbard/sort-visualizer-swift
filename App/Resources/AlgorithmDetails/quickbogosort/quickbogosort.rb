def sort(arr, start = 0, e = arr.length)
  return if start >= e - 1

  pivot = start

  is_partitioned = lambda do
    (start...pivot).each do |i|
      return false if arr[i] > arr[pivot]
    end
    ((pivot + 1)...e).each do |i|
      return false if arr[pivot] > arr[i]
    end
    true
  end

  until is_partitioned.call
    (start...e).each do |i|
      j = rand(i..(e - 1))
      if pivot == i
        pivot = j
      elsif pivot == j
        pivot = i
      end
      arr[i], arr[j] = arr[j], arr[i]
    end
  end

  sort(arr, start, pivot)
  sort(arr, pivot + 1, e)
end

array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
p array
