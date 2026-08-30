def swap2(arr, i, j)
  arr[i], arr[j] = arr[j], arr[i]
end

def reverse_inclusive(arr, lo, hi)
  while lo < hi
    swap2(arr, lo, hi)
    lo += 1
    hi -= 1
  end
end

# -- Fixed-size sorting networks --------------------------------------------------------------

def swap_two(arr, start)
  swap2(arr, start, start + 1) if arr[start] > arr[start + 1]
end

def swap_three(arr, start)
  if arr[start] > arr[start + 1]
    if arr[start] <= arr[start + 2]
      swap2(arr, start, start + 1)
    elsif arr[start + 1] > arr[start + 2]
      swap2(arr, start, start + 2)
    else
      temp = arr[start]
      arr[start] = arr[start + 1]
      arr[start + 1] = arr[start + 2]
      arr[start + 2] = temp
    end
  elsif arr[start + 1] > arr[start + 2]
    if arr[start] > arr[start + 2]
      temp = arr[start + 2]
      arr[start + 2] = arr[start + 1]
      arr[start + 1] = arr[start]
      arr[start] = temp
    else
      swap2(arr, start + 2, start + 1)
    end
  end
end

def swap_four(arr, start)
  swap2(arr, start, start + 1) if arr[start] > arr[start + 1]
  swap2(arr, start + 2, start + 3) if arr[start + 2] > arr[start + 3]
  if arr[start + 1] > arr[start + 2]
    if arr[start] <= arr[start + 2]
      if arr[start + 1] <= arr[start + 3]
        swap2(arr, start + 1, start + 2)
      else
        temp = arr[start + 1]
        arr[start + 1] = arr[start + 2]
        arr[start + 2] = arr[start + 3]
        arr[start + 3] = temp
      end
    elsif arr[start] > arr[start + 3]
      swap2(arr, start + 1, start + 3)
      swap2(arr, start, start + 2)
    elsif arr[start + 1] <= arr[start + 3]
      temp = arr[start + 1]
      arr[start + 1] = arr[start]
      arr[start] = arr[start + 2]
      arr[start + 2] = temp
    else
      temp = arr[start + 1]
      arr[start + 1] = arr[start]
      arr[start] = arr[start + 2]
      arr[start + 2] = arr[start + 3]
      arr[start + 3] = temp
    end
  end
end

# Inserts the element at `end` into the already-sorted run [start, end - 1] (always exactly 4
# elements: swap_four runs immediately before every call site). Returns the new `end`.
def swap_five(arr, start, _end_pos)
  end_pos = start + 4
  pta = end_pos
  end_pos += 1
  ptt = pta
  pta -= 1

  if arr[pta] > arr[ptt]
    key = arr[ptt]
    arr[ptt] = arr[pta]
    ptt -= 1
    pta -= 1

    if pta > start && arr[pta - 1] > key
      arr[ptt] = arr[pta]
      ptt -= 1
      pta -= 1
      arr[ptt] = arr[pta]
      ptt -= 1
      pta -= 1
    end

    if pta >= start && arr[pta] > key
      arr[ptt] = arr[pta]
      ptt -= 1
      pta - 1
    end

    arr[ptt] = key
  end
  end_pos
end

# Same shift logic as swap_five, one neighbor further out (checks pta - 2 first). Returns the new
# `end`.
def tail_swap_eight(arr, start, end_pos)
  pta = end_pos
  end_pos += 1
  ptt = pta
  pta -= 1

  if arr[pta] > arr[ptt]
    key = arr[ptt]
    arr[ptt] = arr[pta]
    ptt -= 1
    pta -= 1

    if arr[pta - 2] > key
      3.times do
        arr[ptt] = arr[pta]
        ptt -= 1
        pta -= 1
      end
    end

    if pta > start && arr[pta - 1] > key
      arr[ptt] = arr[pta]
      ptt -= 1
      pta -= 1
      arr[ptt] = arr[pta]
      ptt -= 1
      pta -= 1
    end

    if pta >= start && arr[pta] > key
      arr[ptt] = arr[pta]
      ptt -= 1
      pta -= 1
    end

    arr[ptt] = key
  end
  end_pos
end

def swap_six(arr, start, end_pos)
  end_pos = swap_five(arr, start, end_pos)
  tail_swap_eight(arr, start, end_pos)
end

def swap_seven(arr, start, end_pos)
  end_pos = swap_six(arr, start, end_pos)
  tail_swap_eight(arr, start, end_pos)
end

def swap_eight(arr, start, end_pos)
  end_pos = swap_seven(arr, start, end_pos)
  tail_swap_eight(arr, start, end_pos)
end

# ~4 items: one of the fixed sorting networks above. 5+: an unguarded insertion sort -- swap_five
# through swap_eight handle the first 5-8 elements by hand, then a binary-search insertion (the
# `while top > 1` loop) places everything past index 8.
def tail_swap(arr, start, nmemb)
  end_pos = 0
  case nmemb
  when 0, 1
    return
  when 2
    swap_two(arr, start)
    return
  when 3
    swap_three(arr, start)
    return
  when 4
    swap_four(arr, start)
    return
  when 5
    swap_four(arr, start)
    swap_five(arr, start, end_pos)
    return
  when 6
    swap_four(arr, start)
    swap_six(arr, start, end_pos)
    return
  when 7
    swap_four(arr, start)
    swap_seven(arr, start, end_pos)
    return
  when 8
    swap_four(arr, start)
    swap_eight(arr, start, end_pos)
    return
  end

  swap_four(arr, start)
  swap_eight(arr, start, end_pos)
  end_pos = start + 8
  offset = 8

  while offset < nmemb
    top = offset
    offset += 1
    pta = end_pos
    end_pos += 1
    ptt = pta
    pta -= 1

    next if arr[pta] <= arr[ptt]

    temp = arr[ptt]
    while top > 1
      mid = top / 2
      pta -= mid if arr[pta - mid] > temp
      top -= mid
    end

    i = ptt
    while i > pta
      arr[i] = arr[i - 1]
      i -= 1
    end
    arr[pta] = temp
  end
end

# -- Parity merges (merge 4+4 into 8, or 8+8 into 16, tracking both ends at once) ---------------

# Merges the two 4-element runs at [start, start+4) and [start+4, start+8) from the main array
# into dest (a scratch buffer), working from both ends toward the middle simultaneously --
# forward comparisons use <= and backward ones use >, which is what keeps this stable.
def parity_merge4(arr, start, dest, aux_offset)
  aux_p = aux_offset
  ptl = start
  ptr = start + 4

  3.times do
    if arr[ptl] <= arr[ptr]
      dest[aux_p] = arr[ptl]
      ptl += 1
    else
      dest[aux_p] = arr[ptr]
      ptr += 1
    end
    aux_p += 1
  end
  dest[aux_p] = (arr[ptl] <= arr[ptr]) ? arr[ptl] : arr[ptr]

  ptl = start + 3
  ptr = start + 7
  aux_p += 4

  3.times do
    if arr[ptl] > arr[ptr]
      dest[aux_p] = arr[ptl]
      ptl -= 1
    else
      dest[aux_p] = arr[ptr]
      ptr -= 1
    end
    aux_p -= 1
  end
  dest[aux_p] = (arr[ptl] > arr[ptr]) ? arr[ptl] : arr[ptr]
end

# Same shape as parity_merge4, one level up: merges two 8-element runs from `from` (a scratch
# buffer) back into the main array.
def parity_merge8(arr, from, start)
  main_p = start
  ptl = 0
  ptr = 8

  7.times do
    if from[ptl] <= from[ptr]
      arr[main_p] = from[ptl]
      ptl += 1
    else
      arr[main_p] = from[ptr]
      ptr += 1
    end
    main_p += 1
  end
  arr[main_p] = (from[ptl] <= from[ptr]) ? from[ptl] : from[ptr]

  ptl = 7
  ptr = 15
  main_p += 8

  7.times do
    if from[ptl] > from[ptr]
      arr[main_p] = from[ptl]
      ptl -= 1
    else
      arr[main_p] = from[ptr]
      ptr -= 1
    end
    main_p -= 1
  end
  arr[main_p] = (from[ptl] > from[ptr]) ? from[ptl] : from[ptr]
end

# Merges four already-sorted 4-element runs (16 elements total) via two parity_merge4 passes into
# aux, then one parity_merge8 pass back -- but only if they aren't already sorted, which the three
# comparisons below check cheaply.
def parity_merge16(arr, start, aux)
  return if arr[start + 3] <= arr[start + 4] && arr[start + 7] <= arr[start + 8] &&
    arr[start + 11] <= arr[start + 12]

  parity_merge4(arr, start, aux, 0)
  parity_merge4(arr, start + 8, aux, 8)
  parity_merge8(arr, aux, start)
end

# -- Bottom-up tail merge (arrays under 256, and quad_merge's own fallback tail) -----------------

def partial_backward_merge(arr, aux, start, nmemb, block)
  m = start + block
  e = start + nmemb - 1
  r = m
  m -= 1

  return if arr[m] <= arr[r]

  e -= 1 while arr[m] <= arr[e]

  (r...(r + (e - m))).each { |i| aux[i - r] = arr[i] }

  s = e - r
  arr[e] = arr[m]
  e -= 1
  m -= 1

  if arr[start] <= aux[0]
    loop do
      while arr[m] > aux[s]
        arr[e] = arr[m]
        e -= 1
        m -= 1
      end
      arr[e] = aux[s]
      e -= 1
      s -= 1
      break if s < 0
    end
  else
    loop do
      while arr[m] <= aux[s]
        arr[e] = aux[s]
        e -= 1
        s -= 1
      end
      arr[e] = arr[m]
      e -= 1
      m -= 1
      break if m < start
    end
    loop do
      arr[e] = aux[s]
      e -= 1
      s -= 1
      break if s < 0
    end
  end
end

# Bottom-up merge pass: doubles `block` each round, merging every adjacent pair of runs at the
# current width via partial_backward_merge, until `block` covers the whole [start, start + nmemb)
# range. Used directly for arrays under 256, and as quad_merge's fallback tail for whatever
# doesn't divide evenly into quad blocks.
def tail_merge(arr, aux, start, nmemb, block)
  pte = start + nmemb

  while block < nmemb
    pta = start
    while pta + block < pte
      if pta + block * 2 < pte
        partial_backward_merge(arr, aux, pta, block * 2, block)
        pta += block * 2
        next
      end
      partial_backward_merge(arr, aux, pta, pte - pta, block)
      break
    end
    block *= 2
  end
end

# -- Quad merge (arrays 256 and up) -------------------------------------------------------------

def forward_merge_read(arr, aux, to_aux, i)
  to_aux ? arr[i] : aux[i]
end

def forward_merge_write(arr, aux, to_aux, i, value)
  if to_aux
    aux[i] = value
  else
    arr[i] = value
  end
end

# Merges main-array run [start, start+block) with aux-buffer run starting at aux_start (or vice
# versa, controlled by to_aux) into the other side.
def forward_merge(arr, aux, start, aux_start, block, to_aux)
  merge_p = to_aux ? aux_start : start
  l = to_aux ? start : aux_start
  r = to_aux ? (start + block) : (aux_start + block)
  m = r
  e = r + block

  if forward_merge_read(arr, aux, to_aux, r - 1) <= forward_merge_read(arr, aux, to_aux, e - 1)
    while l < m
      if forward_merge_read(arr, aux, to_aux, l) <= forward_merge_read(arr, aux, to_aux, r)
        forward_merge_write(arr, aux, to_aux, merge_p, forward_merge_read(arr, aux, to_aux, l))
        merge_p += 1
        l += 1
      else
        forward_merge_write(arr, aux, to_aux, merge_p, forward_merge_read(arr, aux, to_aux, r))
        merge_p += 1
        r += 1
      end
    end
    while r < e
      forward_merge_write(arr, aux, to_aux, merge_p, forward_merge_read(arr, aux, to_aux, r))
      merge_p += 1
      r += 1
    end
  else
    while r < e
      if forward_merge_read(arr, aux, to_aux, l) > forward_merge_read(arr, aux, to_aux, r)
        forward_merge_write(arr, aux, to_aux, merge_p, forward_merge_read(arr, aux, to_aux, r))
        merge_p += 1
        r += 1
      else
        forward_merge_write(arr, aux, to_aux, merge_p, forward_merge_read(arr, aux, to_aux, l))
        merge_p += 1
        l += 1
      end
    end
    while l < m
      forward_merge_write(arr, aux, to_aux, merge_p, forward_merge_read(arr, aux, to_aux, l))
      merge_p += 1
      l += 1
    end
  end
end

# Merges 4 adjacent `block`-sized runs ([start, start+4*block)) into one sorted run, via up to 3
# already-sorted fast-path checks that skip straight to a smaller merge -- or none at all -- when
# consecutive runs are already in order.
def quad_merge_block(arr, start, aux, block)
  block_x2 = block * 2
  c_max = start + block

  if arr[c_max - 1] <= arr[c_max]
    c_max += block_x2

    if arr[c_max - 1] <= arr[c_max]
      c_max -= block

      return if arr[c_max - 1] <= arr[c_max]

      pts = 0
      c = start
      loop do
        aux[pts] = arr[c]
        c += 1
        pts += 1
        break unless c < c_max
      end

      c_max = c + block_x2
      loop do
        aux[pts] = arr[c]
        c += 1
        pts += 1
        break unless c < c_max
      end

      forward_merge(arr, aux, start, 0, block_x2, false)
      return
    end

    pts = 0
    c = start
    c_max = start + block_x2
    loop do
      aux[pts] = arr[c]
      c += 1
      pts += 1
      break unless c < c_max
    end
  else
    forward_merge(arr, aux, start, 0, block, true)
  end

  forward_merge(arr, aux, start + block_x2, block_x2, block, true)
  forward_merge(arr, aux, start, 0, block_x2, false)
end

# Quad-merges the entire [start, start+nmemb) range, doubling `block` by 4 each round; falls back
# to tail_merge for whatever doesn't divide evenly into quad blocks at the current size, and again
# at the very end for the final, coarsest remainder.
def quad_merge(arr, aux, start, nmemb, block)
  pte = start + nmemb
  block *= 4

  while block * 2 <= nmemb
    pta = start
    loop do
      quad_merge_block(arr, pta, aux, block / 4)
      pta += block
      break unless pta + block <= pte
    end
    tail_merge(arr, aux, pta, pte - pta, block / 4)
    block *= 4
  end
  tail_merge(arr, aux, start, nmemb, block / 4)
end

# -- Pre-sort pass -------------------------------------------------------------------------------

# Pre-sorting pass: a 4-item sorting network applied across the whole range, with a side detector
# for strictly-decreasing runs -- reversed in place rather than merged, since a reversal is
# cheaper and exactly reproduces a decreasing run's sorted order. If the *entire* range turns out
# strictly decreasing, one reversal finishes the sort outright (returns true); otherwise this
# finishes with parity-merge passes over what's left (returns false, meaning the caller still has
# more merging to do).
#
# The original C source expresses this with `goto` between the outer "swapper" loop and an inner
# "innerB" loop. Ruby has neither goto nor labeled loops, so the two loops are flattened into one
# `loop do ... end` driven by an `in_inner_b` mode flag: `next` while the flag is unchanged plays
# the role of a same-loop `continue`/`goto swapper_continue` handled without switching modes,
# flipping `in_inner_b` before `next` plays the role of `goto innerB` / falling back out of it, and
# `break` plays `goto swapper_end`.
def quad_swap(arr, start, nmemb)
  swap_buf = Array.new(16, 0)
  pta = start
  count = nmemb / 4
  pts = 0
  in_inner_b = false

  loop do
    unless in_inner_b
      break if count <= 0
      count -= 1

      if arr[pta] > arr[pta + 1]
        if arr[pta + 2] > arr[pta + 3]
          if arr[pta + 1] > arr[pta + 2]
            pts = pta
            pta += 4
            in_inner_b = true
            next
          end
          swap2(arr, pta + 2, pta + 3)
        end
        swap2(arr, pta, pta + 1)
      elsif arr[pta + 2] > arr[pta + 3]
        swap2(arr, pta + 2, pta + 3)
      end

      if arr[pta + 1] > arr[pta + 2]
        if arr[pta] <= arr[pta + 2]
          if arr[pta + 1] <= arr[pta + 3]
            swap2(arr, pta + 1, pta + 2)
          else
            temp = arr[pta + 1]
            arr[pta + 1] = arr[pta + 2]
            arr[pta + 2] = arr[pta + 3]
            arr[pta + 3] = temp
          end
        elsif arr[pta] > arr[pta + 3]
          swap2(arr, pta + 1, pta + 3)
          swap2(arr, pta, pta + 2)
        elsif arr[pta + 1] <= arr[pta + 3]
          temp = arr[pta + 1]
          arr[pta + 1] = arr[pta]
          arr[pta] = arr[pta + 2]
          arr[pta + 2] = temp
        else
          temp = arr[pta + 1]
          arr[pta + 1] = arr[pta]
          arr[pta] = arr[pta + 2]
          arr[pta + 2] = arr[pta + 3]
          arr[pta + 3] = temp
        end
      end
      pta += 4
      next
    end

    # innerB
    if count > 0
      count -= 1

      if arr[pta] > arr[pta + 1]
        if arr[pta + 2] > arr[pta + 3]
          if arr[pta + 1] > arr[pta + 2]
            if arr[pta - 1] > arr[pta]
              pta += 4
              next
            end
          end
          swap2(arr, pta + 2, pta + 3)
        end
        swap2(arr, pta, pta + 1)
      elsif arr[pta + 2] > arr[pta + 3]
        swap2(arr, pta + 2, pta + 3)
      end

      if arr[pta + 1] > arr[pta + 2]
        if arr[pta] <= arr[pta + 2]
          if arr[pta + 1] <= arr[pta + 3]
            swap2(arr, pta + 1, pta + 2)
          else
            temp = arr[pta + 1]
            arr[pta + 1] = arr[pta + 2]
            arr[pta + 2] = arr[pta + 3]
            arr[pta + 3] = temp
          end
        elsif arr[pta] > arr[pta + 3]
          swap2(arr, pta, pta + 2)
          swap2(arr, pta + 1, pta + 3)
        elsif arr[pta + 1] <= arr[pta + 3]
          temp = arr[pta]
          arr[pta] = arr[pta + 2]
          arr[pta + 2] = arr[pta + 1]
          arr[pta + 1] = temp
        else
          temp = arr[pta]
          arr[pta] = arr[pta + 2]
          arr[pta + 2] = arr[pta + 3]
          arr[pta + 3] = arr[pta + 1]
          arr[pta + 1] = temp
        end
      end

      reverse_inclusive(arr, pts, pta - 1)
      pta += 4
      in_inner_b = false
      next
    end

    if pts == start
      remainder = nmemb % 4
      remainder = (arr[pta + 1] > arr[pta + 2]) ? 2 : -1 if remainder == 3
      remainder = (arr[pta] > arr[pta + 1]) ? 1 : -1 if remainder == 2
      remainder = (arr[pta - 1] > arr[pta]) ? 0 : -1 if remainder == 1
      if remainder == 0
        reverse_inclusive(arr, pts, pts + nmemb - 1)
        return true
      end
    end

    reverse_inclusive(arr, pts, pta - 1)
    break
  end

  tail_swap(arr, pta, nmemb % 4)

  pta = start
  count = nmemb / 16
  while count > 0
    count -= 1
    parity_merge16(arr, pta, swap_buf)
    pta += 16
  end

  tail_merge(arr, swap_buf, pta, nmemb % 16, 4) if nmemb % 16 > 4

  false
end

# -- Entry points into the embedded quadsort core -----------------------------------------------

# Top-level dispatch by size: under 16 is a plain tail_swap; under 256 pre-sorts via quad_swap then
# finishes with tail_merge; 256 and up finishes with the full quad_merge pass instead. Allocates
# its own scratch buffer each call.
def quad_sort_range(arr, start, length)
  if length < 16
    tail_swap(arr, start, length)
  elsif length < 256
    unless quad_swap(arr, start, length)
      buffer = Array.new(128, 0)
      tail_merge(arr, buffer, start, length, 16)
    end
  else
    unless quad_swap(arr, start, length)
      buffer = Array.new(length / 2, 0)
      quad_merge(arr, buffer, start, length, 16)
    end
  end
end

# Same dispatch as quad_sort_range, but merges into `swap_buf` -- a caller-supplied scratch buffer
# -- instead of allocating a fresh one. FluxSort uses this to reuse one top-level scratch buffer
# across every depth of its own recursive partition.
def quad_sort_range_using(arr, swap_buf, start, length)
  if length < 16
    tail_swap(arr, start, length)
  elsif length < 256
    tail_merge(arr, swap_buf, start, length, 16) unless quad_swap(arr, start, length)
  else
    quad_merge(arr, swap_buf, start, length, 16) unless quad_swap(arr, start, length)
  end
end

# -- FluxSort's own recursive partition --------------------------------------------------------

FLUX_OUT = 24

# One adjacent-pair scan counting inversions ("balance"). Returns false whenever the array was
# fully handled without partitioning: already sorted, fully reverse-sorted (one reversal away from
# sorted), or mostly-sorted-or-reversed enough (balance within 1/6 of either end) that a plain
# quad_sort_range wins outright. Returns true only when real partitioning in flux_partition is
# worthwhile.
def flux_analyze(arr, nmemb)
  balance = 0
  pta = 0
  cnt = nmemb
  loop do
    cnt -= 1
    break if cnt <= 0
    left = pta
    pta += 1
    balance += 1 if arr[left] > arr[pta]
  end

  return false if balance == 0

  if balance == nmemb - 1
    reverse_inclusive(arr, 0, nmemb - 1)
    return false
  end

  if balance <= nmemb / 6 || balance >= nmemb / 6 * 5
    quad_sort_range(arr, 0, nmemb)
    return false
  end

  true
end

# true if main[a] > main[b], else false. Branches on main_is_swap per fluxsort's aux-vs-main
# comparison rule: comparisons against the live array are real; comparisons against the swap
# buffer (once a recursive call is reading from it instead) are bare value comparisons.
def main_gt(arr, swap_buf, main_is_swap, a, b)
  main_is_swap ? (swap_buf[a] > swap_buf[b]) : (arr[a] > arr[b])
end

# Median-of-3 index tournament.
def median_of_three(arr, swap_buf, main_is_swap, v0, v1, v2)
  val = main_gt(arr, swap_buf, main_is_swap, v0, v1) ? 1 : 0
  t0 = val
  t1 = val ^ 1

  val = main_gt(arr, swap_buf, main_is_swap, v0, v2) ? 1 : 0
  t0 += val
  return v0 if t0 == 1

  val = main_gt(arr, swap_buf, main_is_swap, v1, v2) ? 1 : 0
  t1 += val
  (t1 == 1) ? v1 : v2
end

# Median-of-5 index tournament.
def median_of_five(arr, swap_buf, main_is_swap, v0, v1, v2, v3, v4)
  val = main_gt(arr, swap_buf, main_is_swap, v0, v1) ? 1 : 0
  t0 = val
  t1 = val ^ 1

  val = main_gt(arr, swap_buf, main_is_swap, v0, v2) ? 1 : 0
  t0 += val
  t2 = val ^ 1

  val = main_gt(arr, swap_buf, main_is_swap, v0, v3) ? 1 : 0
  t0 += val
  t3 = val ^ 1

  val = main_gt(arr, swap_buf, main_is_swap, v0, v4) ? 1 : 0
  t0 += val

  return v0 if t0 == 2

  val = main_gt(arr, swap_buf, main_is_swap, v1, v2) ? 1 : 0
  t1 += val
  t2 += val ^ 1

  val = main_gt(arr, swap_buf, main_is_swap, v1, v3) ? 1 : 0
  t1 += val
  t3 += val ^ 1

  val = main_gt(arr, swap_buf, main_is_swap, v1, v4) ? 1 : 0
  t1 += val

  return v1 if t1 == 2

  val = main_gt(arr, swap_buf, main_is_swap, v2, v3) ? 1 : 0
  t2 += val
  t3 += val ^ 1

  val = main_gt(arr, swap_buf, main_is_swap, v2, v4) ? 1 : 0
  t2 += val

  return v2 if t2 == 2

  val = main_gt(arr, swap_buf, main_is_swap, v3, v4) ? 1 : 0
  t3 += val

  (t3 == 2) ? v3 : v4
end

# Picks a pivot from 9 evenly-spaced samples via 3 median-of-3s feeding one more -- used when the
# partition being pivoted is at most 1024 elements.
def median_of_nine(arr, swap_buf, main_is_swap, ptx, nmemb)
  div = nmemb / 16
  v0 = median_of_three(arr, swap_buf, main_is_swap, ptx + div * 2, ptx + div * 1, ptx + div * 4)
  v1 = median_of_three(arr, swap_buf, main_is_swap, ptx + div * 8, ptx + div * 6, ptx + div * 10)
  v2 = median_of_three(arr, swap_buf, main_is_swap, ptx + div * 14, ptx + div * 12, ptx + div * 15)
  median_of_three(arr, swap_buf, main_is_swap, v0, v1, v2)
end

# Picks a pivot from 15 evenly-spaced samples via 5 median-of-3s feeding one median-of-5 -- used
# once the partition being pivoted exceeds 1024 elements.
def median_of_fifteen(arr, swap_buf, main_is_swap, ptx, nmemb)
  div = nmemb / 16
  v0 = median_of_three(arr, swap_buf, main_is_swap, ptx + div * 2, ptx + div * 1, ptx + div * 3)
  v1 = median_of_three(arr, swap_buf, main_is_swap, ptx + div * 5, ptx + div * 4, ptx + div * 6)
  v2 = median_of_three(arr, swap_buf, main_is_swap, ptx + div * 8, ptx + div * 7, ptx + div * 9)
  v3 = median_of_three(arr, swap_buf, main_is_swap, ptx + div * 11, ptx + div * 10, ptx + div * 12)
  v4 = median_of_three(arr, swap_buf, main_is_swap, ptx + div * 14, ptx + div * 13, ptx + div * 15)
  median_of_five(arr, swap_buf, main_is_swap, v2, v0, v1, v3, v4)
end

# The core recursive partition. Reads "main" (the live array if !main_is_swap, else swap_buf) left
# to right starting at main_is_swap ? 0 : start, picks a pivot via median_of_nine/median_of_fifteen,
# then for every element unconditionally writes it to BOTH the array (at the forward cursor pta)
# and swap_buf (at the forward cursor pts) -- but only advances whichever cursor is that element's
# real destination (value > piv -> swap_buf/pts, else array/pta). This is fluxsort's branchless
# partition trick: the "wrong" write for an element is simply overwritten later by the next
# element that really belongs at that slot, so no conditional/branch is needed to pick a
# destination up front. Recurses into whichever side still needs it (skipping straight to
# quad_sort_range_using once a side is small or skewed enough), high side first.
def flux_partition(arr, swap_buf, main_is_swap, start, nmemb)
  ptx_base = main_is_swap ? 0 : start
  median_index = (nmemb > 1024) ? median_of_fifteen(arr, swap_buf, main_is_swap, ptx_base, nmemb) :
                                 median_of_nine(arr, swap_buf, main_is_swap, ptx_base, nmemb)
  piv = main_is_swap ? swap_buf[median_index] : arr[median_index]

  pte = ptx_base + nmemb
  pta = start
  pts = 0
  ptx = ptx_base

  while ptx < pte
    value = main_is_swap ? swap_buf[ptx] : arr[ptx]
    val = (value > piv) ? 1 : 0

    arr[pta] = value
    pta += 1 - val

    swap_buf[pts] = value
    pts += val

    ptx += 1
  end

  s_size = pts
  a_size = nmemb - s_size

  if a_size <= s_size / 16 || s_size <= FLUX_OUT
    (0...s_size).each { |i| arr[pta + i] = swap_buf[i] }
    quad_sort_range_using(arr, swap_buf, pta, s_size)
  else
    flux_partition(arr, swap_buf, true, pta, s_size)
  end

  if s_size <= a_size / 16 || a_size <= FLUX_OUT
    quad_sort_range_using(arr, swap_buf, start, a_size)
  else
    flux_partition(arr, swap_buf, false, start, a_size)
  end
end

# -- Entry point ---------------------------------------------------------------------------------

# Below this size, bottoms out into the embedded quadsort outright rather than partitioning at
# all -- matches fluxsort's own `nmemb < 32` fast path.
def sort(arr)
  n = arr.length
  return if n < 2

  if n < 32
    quad_sort_range(arr, 0, n)
    return
  end

  return unless flux_analyze(arr, n)

  swap_buf = Array.new(n, 0)
  flux_partition(arr, swap_buf, false, 0, n)
end

array = [
  55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51,
  66, 29, 44, 12, 90, 1, 58, 33, 71, 19, 60, 45, 27, 82, 6, 95, 38, 63, 9, 50
]
sort(array)
p array
