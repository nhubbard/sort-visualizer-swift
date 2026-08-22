def snuffle_sort(arr, start, stop)
  if stop - start + 1 >= 2
    if arr[start] > arr[stop]
      arr[start], arr[stop] = arr[stop], arr[start]
    end
    if stop - start + 1 >= 3
      mid = (stop - start) / 2 + start
      iterations = (stop - start + 1) / 2
      iterations.times do
        snuffle_sort(arr, start, mid)
        snuffle_sort(arr, mid, stop)
      end
    end
  end
end

def sort(array)
  snuffle_sort(array, 0, array.length - 1)
end

array = [0, 39, 21, 62, 91, 77, 14, 23]
sort(array)
p array
