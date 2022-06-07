def bubble_sort(array)
  n = array.length()
  c = 0
  while c < n - 1
    d = 0
    while d < n - c - 1
      if array[d] > array[d + 1]
        array[d], array[d + 1] = array[d + 1], array[d]
      end
      d += 1
    end
    c += 1
  end
end

items = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
bubble_sort(items)
p items
