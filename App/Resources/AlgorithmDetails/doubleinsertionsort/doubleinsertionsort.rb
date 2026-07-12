def double_insertion_sort(array, start, last)
  left = start + (last - start) / 2 - 1
  right = left + 1
  if array[left] > array[right]
    array[left], array[right] = array[right], array[left]
  end
  left -= 1
  right += 1

  while left >= start && right < last
    if array[left] > array[right]
      left_item = array[right]
      right_item = array[left]

      pos = left + 1
      while pos <= right && array[pos] <= left_item
        array[pos - 1] = array[pos]
        pos += 1
      end
      array[pos - 1] = left_item

      pos = right - 1
      while pos >= left && array[pos] >= right_item
        array[pos + 1] = array[pos]
        pos -= 1
      end
      array[pos + 1] = right_item
    else
      left_item = array[left]
      right_item = array[right]

      pos = left + 1
      while array[pos] < left_item
        array[pos - 1] = array[pos]
        pos += 1
      end
      array[pos - 1] = left_item

      pos = right - 1
      while array[pos] > right_item
        array[pos + 1] = array[pos]
        pos -= 1
      end
      array[pos + 1] = right_item
    end

    left -= 1
    right += 1
  end

  if right < last
    pos = right - 1
    current = array[right]
    while pos >= start && array[pos] > current
      array[pos + 1] = array[pos]
      pos -= 1
    end
    array[pos + 1] = current
  end
end

def sort(array)
  double_insertion_sort(array, 0, array.length) if array.length > 1
  return array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
