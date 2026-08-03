class Node
  attr_accessor :value, :level, :left, :right

  def initialize(value)
    @value = value
    @level = 0
    @left = nil
    @right = nil
  end
end

def level(node)
  node.nil? ? -1 : node.level
end

def skew(node)
  return node if node.left.nil?

  l = node.left
  node.left = l.right
  l.right = node
  l
end

def split(node)
  return node if node.right.nil?

  r = node.right
  node.right = r.left
  r.left = node
  r.level += 1
  r
end

def add(node, value)
  return Node.new(value) if node.nil?

  if value < node.value
    node.left = add(node.left, value)
    if level(node.left) == node.level
      return skew(node) if node.level != level(node.right)

      node.level += 1
    end
  else
    node.right = add(node.right, value)
    return split(node) if level(node.right.right) == node.level
  end
  node
end

def traverse(node, result)
  return if node.nil?

  traverse(node.left, result)
  result << node.value
  traverse(node.right, result)
end

def sort(arr)
  n = arr.length
  root = nil
  (0...n).each { |i| root = add(root, arr[i]) }

  result = []
  traverse(root, result)

  (0...n).each { |i| arr[i] = result[i] }
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
