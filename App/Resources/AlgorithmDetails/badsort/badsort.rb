def sort(array)
  current_len = array.length
  (0...current_len).each do |i|
    shortest = i

    j = i
    while j < current_len
      is_shortest = true
      k = j + 1
      while k < current_len
        if array[j] > array[k]
          is_shortest = false
          break
        end
        k += 1
      end

      if is_shortest
        shortest = j
        break
      end
      j += 1
    end

    array[i], array[shortest] = array[shortest], array[i]
  end
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
