def sort(arr)
  n = arr.length
  until arr.each_cons(2).all? { |a, b| a <= b }
    index = rand(n - 1)
    if arr[index] > arr[index + 1]
      arr[index], arr[index + 1] = arr[index + 1], arr[index]
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23]
sort(array)
p array
