def sort(arr, length = arr.length)
  return if length == 1
  sort(arr, length - 1)
  while arr[length - 2] > arr[length - 1]
    sub = arr[0...length].shuffle
    arr[0...length] = sub
    sort(arr, length - 1)
  end
end

array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
p array
