def gapped_insertion_sort(array, a, b, gap)
  i = a + gap
  while i < b
    j = i
    while j - gap >= a && array[j] < array[j - gap]
      array[j], array[j - gap] = array[j - gap], array[j]
      j -= gap
    end
    i += gap
  end
end

def recursive_shell_sort(array, start, last, g)
  if start + g <= last
    recursive_shell_sort(array, start, last, 3 * g)
    recursive_shell_sort(array, start + g, last, 3 * g)
    recursive_shell_sort(array, start + (2 * g), last, 3 * g)
    gapped_insertion_sort(array, start, last, g)
  end
end

def sort(array)
  recursive_shell_sort(array, 0, array.length, 1)
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
