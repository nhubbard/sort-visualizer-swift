class Node
  attr_accessor :value, :left, :right, :balance

  def initialize(value)
    @value = value
    @left = nil
    @right = nil
    @balance = 0
  end
end

AddResult = Struct.new(:node, :height_changed)

def single_rotate_right(node)
  b = node.left
  node.left = b.right
  b.right = node
  node.balance = 0
  b.balance = 0
  b
end

def single_rotate_left(node)
  b = node.right
  node.right = b.left
  b.left = node
  node.balance = 0
  b.balance = 0
  b
end

def double_rotate_right(node)
  old_b_balance = node.left.right.balance
  node.left = single_rotate_left(node.left)
  b = single_rotate_right(node)
  b.right.balance = 1 if old_b_balance == -1
  b.left.balance = -1 if old_b_balance == 1
  b
end

def double_rotate_left(node)
  old_b_balance = node.right.left.balance
  node.right = single_rotate_right(node.right)
  b = single_rotate_left(node)
  b.right.balance = 1 if old_b_balance == -1
  b.left.balance = -1 if old_b_balance == 1
  b
end

def height_change_left(node)
  if node.balance != -1
    node.balance -= 1
    return AddResult.new(node, node.balance == -1)
  end
  return AddResult.new(single_rotate_right(node), false) if node.left.balance == -1

  AddResult.new(double_rotate_right(node), false)
end

def height_change_right(node)
  if node.balance != 1
    node.balance += 1
    return AddResult.new(node, node.balance == 1)
  end
  return AddResult.new(single_rotate_left(node), false) if node.right.balance == 1

  AddResult.new(double_rotate_left(node), false)
end

def add(node, value)
  return AddResult.new(Node.new(value), true) if node.nil?

  if value < node.value
    result = add(node.left, value)
    node.left = result.node
    return height_change_left(node) if result.height_changed
  else
    result = add(node.right, value)
    node.right = result.node
    return height_change_right(node) if result.height_changed
  end

  AddResult.new(node, false)
end

def traverse(node, result)
  return if node.nil?

  traverse(node.left, result)
  result << node.value
  traverse(node.right, result)
end

def sort(arr)
  root = nil
  arr.each { |value| root = add(root, value).node }

  result = []
  traverse(root, result)

  (0...arr.length).each { |i| arr[i] = result[i] }
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
