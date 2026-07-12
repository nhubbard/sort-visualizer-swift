def int_pow(base, exponent)
  result = 1
  exponent.times { result *= base }
  return result
end

def get_digit(value, power, radix)
  return (value / int_pow(radix, power)) % radix
end

def radix_msd(array, low, high, radix, power)
  return if low >= high || power < 0

  buckets = Array.new(radix) { [] }
  (low...high).each do |i|
    buckets[get_digit(array[i], power, radix)] << array[i]
  end

  index = low
  buckets.each do |bucket|
    bucket.each do |value|
      array[index] = value
      index += 1
    end
  end

  start = low
  buckets.each do |bucket|
    radix_msd(array, start, start + bucket.length, radix, power - 1)
    start += bucket.length
  end
end

def sort(arr)
  return arr if arr.length <= 1
  radix = 4
  max_value = arr.max
  highest_power = 0
  probe = radix
  while probe <= max_value
    highest_power += 1
    probe *= radix
  end
  radix_msd(arr, 0, arr.length, radix, highest_power)
  return arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
