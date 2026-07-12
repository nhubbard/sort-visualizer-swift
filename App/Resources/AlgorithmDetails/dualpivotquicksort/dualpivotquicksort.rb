def partition(array, low, high)
  if array[low] > array[high]
    array[low], array[high] = array[high], array[low]
  end
  j = low + 1
  g = high - 1
  k = low + 1
  p = array[low]
  q = array[high]
  while k <= g
    if array[k] < p
      array[k], array[j] = array[j], array[k]
      j += 1
    elsif array[k] >= q
      while array[g] > q && k < g
        g -= 1
      end
      array[k], array[g] = array[g], array[k]
      g -= 1
      if array[k] < p
        array[k], array[j] = array[j], array[k]
        j += 1
      end
    end
    k += 1
  end
  j -= 1
  g += 1
  array[low], array[j] = array[j], array[low]
  array[high], array[g] = array[g], array[high]
  return j, g
end

def dual_pivot_quick_sort(array, low, high)
  if low < high
    j, g = partition(array, low, high)
    dual_pivot_quick_sort(array, low, j - 1)
    dual_pivot_quick_sort(array, j + 1, g - 1)
    dual_pivot_quick_sort(array, g + 1, high)
  end
  return array
end

def sort(array)
  return dual_pivot_quick_sort(array, 0, array.length() - 1)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
