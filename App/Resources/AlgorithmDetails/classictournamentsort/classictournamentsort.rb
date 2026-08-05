def ceil_pow2(value)
  r = 1
  r *= 2 while r < value
  r
end

def tree_compare(array, tree, a, b)
  array[tree[a]] <= array[tree[b]]
end

def find_next(array, tree, size)
  path = tree[0] + size
  while path > 0
    tree[path] = -1
    path = (path - 1) / 2
  end

  node = tree[0] + size
  while node > 0
    sibling = node.odd? ? node + 1 : node - 1
    node_valid = tree[node] != -1
    sibling_valid = tree[sibling] != -1
    winner =
      if node_valid && sibling_valid
        if node < sibling
          tree_compare(array, tree, node, sibling) ? tree[node] : tree[sibling]
        else
          tree_compare(array, tree, sibling, node) ? tree[sibling] : tree[node]
        end
      elsif node_valid
        tree[node]
      elsif sibling_valid
        tree[sibling]
      else
        -1
      end
    node = (node - 1) / 2
    tree[node] = winner if winner != -1
  end
  array[tree[0]]
end

def sort(array)
  n = array.length
  return if n <= 1

  size = ceil_pow2(n) - 1
  mod = n % 2
  tree_size = n + size + mod
  tree = Array.new(tree_size, -1)

  (size...(tree_size - mod)).each do |i|
    tree[i] = i - size
  end

  j = size
  k = tree_size - mod
  while j > 0
    i = j
    while i + 1 < k
      tree[i / 2] = tree_compare(array, tree, i, i + 1) ? tree[i] : tree[i + 1]
      i += 2
    end
    tree[i / 2] = tree[i] if i < k
    j /= 2
    k /= 2
  end

  output = Array.new(n, 0)
  output[0] = array[tree[0]]
  (1...n).each do |i|
    output[i] = find_next(array, tree, size)
  end
  array.replace(output)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
puts "[#{array.join(", ")}]"
