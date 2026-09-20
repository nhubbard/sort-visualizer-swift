def sort(array)
  optimized_dual_pivot_quick_sort(array, 0, array.length - 1, 3)
end

def insertion_sort(a, start, finish)
  (start + 1...finish).each do |i|
    j = i
    while j > start && a[j] < a[j - 1]
      a[j - 1], a[j] = a[j], a[j - 1]
      j -= 1
    end
  end
end

def optimized_dual_pivot_quick_sort(a, left, right, divisor)
  length = right - left
  if length < 27
    insertion_sort(a, left, right + 1)
    return
  end
  third = length / divisor
  med1 = [left + third, left + 1].max
  med2 = [right - third, right - 1].min
  if a[med1] < a[med2]
    a[med1], a[left] = a[left], a[med1]
    a[med2], a[right] = a[right], a[med2]
  else
    a[med1], a[right] = a[right], a[med1]
    a[med2], a[left] = a[left], a[med2]
  end
  pivot1, pivot2 = a[left], a[right]
  less, great = left + 1, right - 1
  k = less
  while k <= great
    if a[k] < pivot1
      a[k], a[less] = a[less], a[k]
      less += 1
    elsif a[k] > pivot2
      great -= 1 while k < great && a[great] > pivot2
      a[k], a[great] = a[great], a[k]
      great -= 1
      if a[k] < pivot1
        a[k], a[less] = a[less], a[k]
        less += 1
      end
    end
    k += 1
  end
  dist = great - less
  divisor += 1 if dist < 13
  a[less - 1], a[left] = a[left], a[less - 1]
  a[great + 1], a[right] = a[right], a[great + 1]
  optimized_dual_pivot_quick_sort(a, left, less - 2, divisor)
  optimized_dual_pivot_quick_sort(a, great + 2, right, divisor)
  if dist > length - 13 && pivot1 != pivot2
    k = less
    while k <= great
      if a[k] == pivot1
        a[k], a[less] = a[less], a[k]; less += 1
      elsif a[k] == pivot2
        a[k], a[great] = a[great], a[k]; great -= 1
        if a[k] == pivot1
          a[k], a[less] = a[less], a[k]; less += 1
        end
      end
      k += 1
    end
  end
  optimized_dual_pivot_quick_sort(a, less, great, divisor) if pivot1 < pivot2
end


array = [
  55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79,
  21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6, 58, 12
]
sort(array)
p array
