INSERTION_RUN = 4

def insertion_sort_range(arr, lo, hi)
  ((lo + 1)...hi).each do |i|
    key = arr[i]
    j = i - 1
    while j >= lo && arr[j] > key
      arr[j + 1] = arr[j]
      j -= 1
    end
    arr[j + 1] = key
  end
end

# Merges the two equal-length sorted runs source[lo...lo+run_length] and
# source[lo+run_length...lo+2*run_length] into dest, filling from both ends toward the middle
# at once instead of scanning front to back alone.
def parity_merge(source, lo, run_length, dest)
  left = lo
  right = lo + run_length
  left_end = lo + run_length - 1
  right_end = lo + (2 * run_length) - 1
  front = lo
  back = lo + (2 * run_length) - 1

  run_length.times do
    if source[left] <= source[right]
      dest[front] = source[left]
      left += 1
    else
      dest[front] = source[right]
      right += 1
    end
    front += 1

    if source[left_end] > source[right_end]
      dest[back] = source[left_end]
      left_end -= 1
    else
      dest[back] = source[right_end]
      right_end -= 1
    end
    back -= 1
  end
end

def merge_range(source, lo, mid, hi, dest)
  left = lo
  right = mid
  out = lo
  while left < mid && right < hi
    if source[left] <= source[right]
      dest[out] = source[left]
      left += 1
    else
      dest[out] = source[right]
      right += 1
    end
    out += 1
  end
  while left < mid
    dest[out] = source[left]
    left += 1
    out += 1
  end
  while right < hi
    dest[out] = source[right]
    right += 1
    out += 1
  end
end

def sort(arr)
  n = arr.length
  return if n < 2
  buffer = arr.dup

  lo = 0
  while lo < n
    insertion_sort_range(arr, lo, [lo + INSERTION_RUN, n].min)
    lo += INSERTION_RUN
  end

  run_length = INSERTION_RUN
  while run_length < n
    lo = 0
    while lo < n
      mid = [lo + run_length, n].min
      hi = [lo + (run_length * 2), n].min
      if mid - lo == run_length && hi - mid == run_length
        parity_merge(arr, lo, run_length, buffer)
      elsif mid < hi
        merge_range(arr, lo, mid, hi, buffer)
      else
        (lo...mid).each { |i| buffer[i] = arr[i] }
      end
      lo += run_length * 2
    end
    (0...n).each { |i| arr[i] = buffer[i] }
    run_length *= 2
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
