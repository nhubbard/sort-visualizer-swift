class Node
  attr_accessor :pointer, :left, :right

  def initialize(pointer)
    @pointer = pointer
    @left = nil
    @right = nil
  end
end

def add(arr, node, add_ptr)
  return Node.new(add_ptr) if node.nil?

  if arr[add_ptr] < arr[node.pointer]
    node.left = add(arr, node.left, add_ptr)
  else
    node.right = add(arr, node.right, add_ptr)
  end
  node
end

def traverse(arr, node, result)
  return if node.nil?

  traverse(arr, node.left, result)
  result << arr[node.pointer]
  traverse(arr, node.right, result)
end

def sort(arr)
  n = arr.length
  root = nil
  (0...n).each { |i| root = add(arr, root, i) }

  result = []
  traverse(arr, root, result)

  (0...n).each { |i| arr[i] = result[i] }
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
