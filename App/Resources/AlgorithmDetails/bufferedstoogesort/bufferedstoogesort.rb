def buffered_stooge_sort(arr, start, stop)
  if stop - start > 1
    if stop - start == 2 && arr[start] > arr[stop - 1]
      arr[start], arr[stop - 1] = arr[stop - 1], arr[start]
    end
    if stop - start > 2
      width = stop - start
      third = (width + 2) / 3 + start
      two_third = (2 * width + 2) / 3 + start
      two_third -= 1 if two_third - third < third
      two_third -= 1 if (width - 2) % 3 == 0

      buffered_stooge_sort(arr, third, two_third)
      buffered_stooge_sort(arr, two_third, stop)

      left = third
      right = two_third
      buffer_start = start
      while left < two_third && right < stop
        if arr[left] > arr[right]
          arr[buffer_start], arr[right] = arr[right], arr[buffer_start]
          right += 1
        else
          arr[buffer_start], arr[left] = arr[left], arr[buffer_start]
          left += 1
        end
        buffer_start += 1
      end
      while right < stop
        arr[buffer_start], arr[right] = arr[right], arr[buffer_start]
        right += 1
        buffer_start += 1
      end

      buffered_stooge_sort(arr, two_third, stop)

      left = two_third - 1
      right = stop - 1
      while right > left && left >= start
        if arr[left] > arr[right]
          (left...right).each do |i|
            arr[i], arr[i + 1] = arr[i + 1], arr[i]
          end
          left -= 1
        end
        right -= 1
      end
    end
  end
end

def sort(arr)
  buffered_stooge_sort(arr, 0, arr.length)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
