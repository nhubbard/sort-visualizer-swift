def swapless_bubble_sort(array)
  i = array.length
  while i > 0
    last = 0
    pos = 0
    comp = array[0]
    (1...i).each do |j|
      if comp > array[j]
        array[j - 1] = array[j]
        last = j
      else
        if pos + 1 < j
          array[j - 1] = comp
        end
        pos = j
        comp = array[j]
      end
    end
    array[i - 1] = comp
    i = last
  end
  return array
end

def sort(array)
  return swapless_bubble_sort(array)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
