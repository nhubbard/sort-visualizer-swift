def insertion_sort(a, start, finish)
  (start + 1...finish).each do |i|
    j = i
    while j > start && a[j] < a[j - 1]
      a[j - 1], a[j] = a[j], a[j - 1]
      j -= 1
    end
  end
end

def dual_pivot_quick_sort(a, left, right, divisor)
  length = right - left
  if length < 4
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
  divisor += 1 if great - less < 13
  a[less - 1], a[left] = a[left], a[less - 1]
  a[great + 1], a[right] = a[right], a[great + 1]
  dual_pivot_quick_sort(a, left, less - 2, divisor)
  dual_pivot_quick_sort(a, less, great, divisor) if pivot1 < pivot2
  dual_pivot_quick_sort(a, great + 2, right, divisor)
end

def sort(array)
  dual_pivot_quick_sort(array, 0, array.length - 1, 3)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
