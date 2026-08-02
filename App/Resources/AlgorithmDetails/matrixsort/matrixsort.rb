MatrixShape = Struct.new(:width, :insert_last)

def dir_compare_val(left, right, dir)
  res = if left > right
    1
  elsif left < right
    -1
  else
    0
  end
  dir ? res : -res
end

def gap_reverse(array, start, fin, gap)
  i = start
  j = fin
  while i < j
    array[i], array[j - gap] = array[j - gap], array[i]
    i += gap
    j -= gap
  end
end

def insert_last(array, a, b, gap, dir)
  did = false
  key = array[b]
  j = b - gap
  while j >= a && dir_compare_val(key, array[j], dir) < 0
    array[j + gap] = array[j]
    did = true
    j -= gap
  end
  array[j + gap] = key
  did
end

def get_matrix_dims(length)
  dim = Integer.sqrt(length)
  insert_last_flag = (dim * dim == length - 1)
  while length % dim != 0
    dim -= 1
  end
  width = dim
  height = length / dim
  unbalanced = (width == 1) != (height == 1)
  MatrixShape.new(width, unbalanced || insert_last_flag)
end

def matrix_sort(array, start, fin, gap, dir)
  length = (fin - start) / gap
  if length < 2
    false
  elsif length <= 16
    did = false
    i = start
    while i < fin
      did = insert_last(array, start, i, gap, dir) || did
      i += gap
    end
    did
  else
    mat_shape = get_matrix_dims(length)
    if mat_shape.insert_last
      did1 = matrix_sort(array, start, fin - gap, gap, dir)
      did2 = insert_last(array, start, fin - gap, gap, dir)
      return did1 || did2
    end

    i = start + mat_shape.width * gap
    while i < fin
      gap_reverse(array, i, i + mat_shape.width * gap, gap)
      i += 2 * mat_shape.width * gap
    end

    did = false
    newdid = true
    while newdid
      newdid = false
      curdir = dir
      i = start
      while i < fin
        newdid = matrix_sort(array, i, i + mat_shape.width * gap, gap, curdir) || newdid
        did ||= newdid
        curdir = !curdir
        i += mat_shape.width * gap
      end

      newdid = false
      (0...mat_shape.width).each do |k|
        newdid = matrix_sort(array, start + k * gap, fin + k * gap, gap * mat_shape.width, dir) || newdid
        did ||= newdid
      end
    end
    i = start + mat_shape.width * gap
    while i < fin
      gap_reverse(array, i, i + mat_shape.width * gap, gap)
      i += 2 * mat_shape.width * gap
    end

    did
  end
end

def sort(arr)
  matrix_sort(arr, 0, arr.length, 1, true)
  arr
end

array = [15, 3, 22, 8, 19, 1, 24, 11, 6, 20,
  9, 17, 2, 14, 23, 5, 18, 0, 12, 21,
  7, 16, 4, 13, 10]
sort(array)
p array
