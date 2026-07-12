def sort(arr)
  arr = arr.shuffle() until arr == arr.sort
  arr.sort
end

array = [0, 39, 21, 62, 91, 77, 14, 23]
array = sort(array)
p array
