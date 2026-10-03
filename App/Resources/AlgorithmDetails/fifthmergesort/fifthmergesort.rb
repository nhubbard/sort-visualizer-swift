def sort(arr)
  sort_range = lambda do |start, finish|
    length = finish - start
    next if length < 2

    bounds = (0..5).map { |part| start + length * part / 5 }
    5.times { |part| sort_range.call(bounds[part], bounds[part + 1]) }

    positions = bounds.first(5)
    merged = []
    while merged.length < length
      best = nil
      5.times do |part|
        next unless positions[part] < bounds[part + 1]
        best = part if best.nil? || arr[positions[part]] < arr[positions[best]]
      end
      merged << arr[positions[best]]
      positions[best] += 1
    end
    arr[start...finish] = merged
  end

  sort_range.call(0, arr.length)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
