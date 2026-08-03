class Node
  attr_accessor :value, :left, :right, :is_red

  def initialize(value)
    @value = value
    @left = nil
    @right = nil
    @is_red = true
  end
end

def red?(node)
  !node.nil? && node.is_red
end

def single_rotate_right(node)
  b = node.left
  node.left = b.right
  b.right = node
  b.is_red = false
  node.is_red = true
  b
end

def single_rotate_left(node)
  b = node.right
  node.right = b.left
  b.left = node
  b.is_red = false
  node.is_red = true
  b
end

def double_rotate_right(node)
  node.left = single_rotate_left(node.left)
  single_rotate_right(node)
end

def double_rotate_left(node)
  node.right = single_rotate_right(node.right)
  single_rotate_left(node)
end

def add(node, value)
  return [Node.new(value), false] if node.nil?

  if !node.is_red && red?(node.left) && red?(node.right)
    node.is_red = true
    node.left.is_red = false
    node.right.is_red = false
  end

  if value < node.value
    child, needs_fix = add(node.left, value)
    node.left = child
    if needs_fix
      return [single_rotate_right(node), false] if red?(node.left.left)
      return [double_rotate_right(node), false]
    end
    [node, node.is_red && red?(node.left)]
  else
    child, needs_fix = add(node.right, value)
    node.right = child
    if needs_fix
      return [single_rotate_left(node), false] if red?(node.right.right)
      return [double_rotate_left(node), false]
    end
    [node, node.is_red && red?(node.right)]
  end
end

def traverse(node, result)
  return if node.nil?

  traverse(node.left, result)
  result << node.value
  traverse(node.right, result)
end

def sort(arr)
  root = nil
  arr.each do |v|
    root, = add(root, v)
    root.is_red = false
  end

  result = []
  traverse(root, result)

  (0...arr.length).each { |i| arr[i] = result[i] }
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
