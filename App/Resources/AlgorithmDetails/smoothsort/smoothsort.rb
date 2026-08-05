LEONARDO = [
  1, 1, 3, 5, 9, 15, 25, 41, 67, 109,
  177, 287, 465, 753, 1219, 1973, 3193, 5167, 8361, 13529, 21891
].freeze

def trailing_zero_count(value)
  mask = value & ~1
  trail = 0
  while mask != 0 && mask & 1 == 0
    mask >>= 1
    trail += 1
  end
  trail
end

def sift(array, pshift_in, head_in)
  pshift = pshift_in
  head = head_in
  val = array[head]
  while pshift > 1
    rt = head - 1
    lf = head - 1 - LEONARDO[pshift - 2]
    break if val >= array[lf] && val >= array[rt]
    if array[lf] >= array[rt]
      array[head] = array[lf]
      head = lf
      pshift -= 1
    else
      array[head] = array[rt]
      head = rt
      pshift -= 2
    end
  end
  array[head] = val
end

def trinkle(array, p_in, pshift_in, head_in, is_trusty_in)
  p = p_in
  pshift = pshift_in
  head = head_in
  is_trusty = is_trusty_in
  val = array[head]
  while p != 1
    stepson = head - LEONARDO[pshift]
    break if array[stepson] <= val
    if !is_trusty && pshift > 1
      rt = head - 1
      lf = head - 1 - LEONARDO[pshift - 2]
      break if array[rt] >= array[stepson] || array[lf] >= array[stepson]
    end
    array[head] = array[stepson]
    head = stepson
    trail = trailing_zero_count(p)
    p >>= trail
    pshift += trail
    is_trusty = false
  end
  unless is_trusty
    array[head] = val
    sift(array, pshift, head)
  end
end

def sort(arr)
  n = arr.length
  return if n <= 1

  head = 0
  p = 1
  pshift = 1
  hi = n - 1

  while head < hi
    if p & 3 == 3
      sift(arr, pshift, head)
      p >>= 2
      pshift += 2
    else
      if LEONARDO[pshift - 1] >= hi - head
        trinkle(arr, p, pshift, head, false)
      else
        sift(arr, pshift, head)
      end
      if pshift == 1
        p <<= 1
        pshift -= 1
      else
        p <<= (pshift - 1)
        pshift = 1
      end
    end
    p |= 1
    head += 1
  end

  trinkle(arr, p, pshift, head, false)
  while pshift != 1 || p != 1
    if pshift <= 1
      trail = trailing_zero_count(p)
      p >>= trail
      pshift += trail
    else
      p <<= 2
      p ^= 7
      pshift -= 2
      trinkle(arr, p >> 1, pshift + 1, head - LEONARDO[pshift] - 1, true)
      trinkle(arr, p, pshift, head - 1, true)
    end
    head -= 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
puts "[#{array.join(", ")}]"
