def cycle_sort(array)
  n = array.length
  (0...(n - 1)).each do |cycle_start|
    item = array[cycle_start]
    pos = cycle_start
    ((cycle_start + 1)...n).each do |i|
      pos += 1 if array[i] < item
    end
    next if pos == cycle_start
    pos += 1 while item == array[pos]
    array[pos], item = item, array[pos]
    while pos != cycle_start
      pos = cycle_start
      ((cycle_start + 1)...n).each do |i|
        pos += 1 if array[i] < item
      end
      pos += 1 while item == array[pos]
      array[pos], item = item, array[pos]
    end
  end
  return array
end

def sort(array)
  return cycle_sort(array)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
