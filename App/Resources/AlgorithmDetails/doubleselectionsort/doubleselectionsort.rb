def double_selection_sort(array)
  n = array.length
  return if n <= 1

  left = 0
  right = n - 1
  smallest = 0
  biggest = 0

  while left <= right
    (left..right).each do |i|
      biggest = i if array[i] > array[biggest]
      smallest = i if array[i] < array[smallest]
    end

    biggest = smallest if biggest == left

    array[left], array[smallest] = array[smallest], array[left]
    array[right], array[biggest] = array[biggest], array[right]

    left += 1
    right -= 1
    smallest = left
    biggest = right
  end
end

def sort(array)
  double_selection_sort(array)
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
