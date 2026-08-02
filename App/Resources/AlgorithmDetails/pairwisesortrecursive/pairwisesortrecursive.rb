def comp_swap(array, a, b)
  return unless array[a] > array[b]
  array[a], array[b] = array[b], array[a]
end

def pairwise_recursive(array, start, fin, gap)
  return if start == fin - gap
  b = start + gap
  while b < fin
    comp_swap(array, b - gap, b)
    b += 2 * gap
  end

  if ((fin - start) / gap) % 2 == 0
    pairwise_recursive(array, start, fin, gap * 2)
    pairwise_recursive(array, start + gap, fin + gap, gap * 2)
  else
    pairwise_recursive(array, start, fin + gap, gap * 2)
    pairwise_recursive(array, start + gap, fin, gap * 2)
  end

  a = 1
  while a < (fin - start) / gap
    a = (a * 2) + 1
  end

  b = start + gap
  while b + gap < fin
    c = a
    while c > 1
      c /= 2
      if b + (c * gap) < fin
        comp_swap(array, b, b + (c * gap))
      end
    end
    b += 2 * gap
  end
end

def sort(arr)
  pairwise_recursive(arr, 0, arr.length, 1)
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
