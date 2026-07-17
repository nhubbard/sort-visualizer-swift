def cocktail_shaker_sort(array)
  n = array.length
  i = 0
  while i < n / 2
    sorted = true
    (i...(n - i - 1)).each do |j|
      if array[j] > array[j + 1]
        array[j], array[j + 1] = array[j + 1], array[j]
        sorted = false
      end
    end
    (i + 1..n - i - 1).reverse_each do |j|
      if array[j] < array[j - 1]
        array[j], array[j - 1] = array[j - 1], array[j]
        sorted = false
      end
    end
    break if sorted
    i += 1
  end
  array
end

def sort(array)
  cocktail_shaker_sort(array)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
