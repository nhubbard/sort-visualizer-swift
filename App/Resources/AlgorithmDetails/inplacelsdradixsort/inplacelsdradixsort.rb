def int_pow(base, exponent)
  result = 1
  exponent.times { result *= base }
  result
end

def get_digit(value, power, radix)
  (value / int_pow(radix, power)) % radix
end

def multi_swap(arr, pos, to)
  if to > pos
    (pos...to).each do |k|
      arr[k], arr[k + 1] = arr[k + 1], arr[k]
    end
  elsif to < pos
    pos.downto(to + 1) do |k|
      arr[k], arr[k - 1] = arr[k - 1], arr[k]
    end
  end
end

def sort(arr)
  n = arr.length
  return arr if n == 0
  radix = 4
  max_value = arr.max

  max_power = 0
  probe = radix
  while probe <= max_value
    max_power += 1
    probe *= radix
  end

  vregs = Array.new(radix - 1, 0)

  (0..max_power).each do |power|
    (0...vregs.length).each { |i| vregs[i] = n - 1 }

    pos = 0
    n.times do
      digit = get_digit(arr[pos], power, radix)
      if digit == 0
        pos += 1
      else
        to = vregs[digit - 1]
        multi_swap(arr, pos, to)
        (digit - 1).downto(1) { |j| vregs[j - 1] -= 1 }
      end
    end
  end
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
