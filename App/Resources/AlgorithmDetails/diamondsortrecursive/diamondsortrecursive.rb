# [start, stop) is the half-open range being sorted. merge selects whether
# the two halves are recursively pre-sorted before the fixed diamond
# comparison pattern below merges them together.
def sort(array, start, stop, merge)
  if stop - start == 2
    if stop <= array.length && array[start] > array[stop - 1]
      array[start], array[stop - 1] = array[stop - 1], array[start]
    end
  elsif stop - start >= 3
    div = (stop - start) / 4.0
    mid = (stop - start) / 2 + start
    quarter = div.to_i + start
    three_quarters = (div * 3).to_i + start

    if merge
      sort(array, start, mid, true)
      sort(array, mid, stop, true)
    end
    sort(array, quarter, three_quarters, false)
    sort(array, start, mid, false)
    sort(array, mid, stop, false)
    sort(array, quarter, three_quarters, false)
  end
end

def sort_array(array)
  return if array.length < 2
  padded_length = 1
  padded_length *= 2 while padded_length < array.length
  sort(array, 0, padded_length, true)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort_array(array)
p array
