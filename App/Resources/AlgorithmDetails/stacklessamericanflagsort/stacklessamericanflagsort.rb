RADIX = 4

def get_digit(value, place)
  place.times { value /= RADIX }
  value % RADIX
end

def shift(value, places)
  places.times { value /= RADIX }
  value
end

# Turns the raw per-bucket counts already accumulated in `counts` into
# starting offsets, then places every element in [start, end) by following
# displacement cycles, one bucket at a time.
def distribute(arr, counts, offsets, start, _end, place)
  (1...RADIX).each do |i|
    counts[i] += counts[i - 1]
    offsets[i] = counts[i - 1]
  end

  (0...RADIX - 1).each do |bucket|
    position = start + offsets[bucket]
    next unless counts[bucket] > offsets[bucket]

    held = arr[position]
    loop do
      digit = get_digit(held, place)
      counts[digit] -= 1
      displaced = arr[start + counts[digit]]
      arr[start + counts[digit]] = held
      held = displaced
      break if counts[bucket] <= offsets[bucket]
    end
  end

  split = start + offsets[1]
  (0...RADIX).each do |i|
    counts[i] = 0
    offsets[i] = 0
  end
  split
end

def sort(arr)
  n = arr.length
  return if n < 2

  q = 0
  probe = RADIX
  max_value = arr.max
  while probe <= max_value
    q += 1
    probe *= RADIX
  end

  counts = Array.new(RADIX, 0)
  offsets = Array.new(RADIX, 0)

  # i/b track the bounds of whichever range is currently active, q the
  # digit place being distributed on, and m a counter that mirrors how many
  # bucket boundaries have already been walked at the current depth,
  # standing in for the call stack a recursive walk would need.
  m = 0
  i = 0
  b = n

  (i...b).each { |j| counts[get_digit(arr[j], q)] += 1 }

  while i < n
    p = (b - i < 1) ? i : distribute(arr, counts, offsets, i, b, q)

    if q.zero?
      m += RADIX
      t = m / RADIX
      while (t % RADIX).zero?
        t /= RADIX
        q += 1
      end

      i = b
      while b < n && shift(arr[b], q + 1) == shift(m, q + 1)
        counts[get_digit(arr[b], q)] += 1
        b += 1
      end
    else
      b = p
      q -= 1
      (i...b).each { |j| counts[get_digit(arr[j], q)] += 1 }
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
