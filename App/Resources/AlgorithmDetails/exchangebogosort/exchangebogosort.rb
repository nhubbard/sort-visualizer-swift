def sort(arr)
  n = arr.length
  until arr.each_cons(2).all? { |a, b| a <= b }
    i = rand(n)
    j = rand(n)
    if (i < j && arr[i] > arr[j]) || (i > j && arr[i] < arr[j])
      arr[i], arr[j] = arr[j], arr[i]
    end
  end
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23]
array = sort(array)
p array
