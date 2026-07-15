require 'set'

def sort(arr, start = 0, e = arr.length)
  return if start >= e - 1

  mid = (start + e) / 2
  sort(arr, start, mid)
  sort(arr, mid, e)

  saved = arr[start...e]

  is_sorted = lambda do
    (start...e - 1).each do |i|
      return false if arr[i] > arr[i + 1]
    end
    true
  end

  until is_sorted.call
    high_positions = (0...e - start).to_a.sample(e - mid).to_set
    low = 0
    high = mid - start
    (0...e - start).each do |offset|
      if high_positions.include?(offset)
        arr[start + offset] = saved[high]
        high += 1
      else
        arr[start + offset] = saved[low]
        low += 1
      end
    end
  end
end

array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
p array
