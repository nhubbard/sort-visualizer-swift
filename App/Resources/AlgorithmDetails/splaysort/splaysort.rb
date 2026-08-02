class Node
  attr_accessor :key, :left, :right

  def initialize(key)
    @key = key
    @left = nil
    @right = nil
  end
end

def left_rotate(x)
  y = x.right
  x.right = y.left
  y.left = x
  y
end

def right_rotate(x)
  y = x.left
  x.left = y.right
  y.right = x
  y
end

def splay(root, key)
  return root if root.nil?
  if root.key > key
    return root if root.left.nil?
    if root.left.key > key
      root.left.left = splay(root.left.left, key)
      root = right_rotate(root)
    else
      root.left.right = splay(root.left.right, key)
      root.left = left_rotate(root.left) unless root.left.right.nil?
    end
    root.left.nil? ? root : right_rotate(root)
  else
    return root if root.right.nil?
    if root.right.key > key
      root.right.left = splay(root.right.left, key)
      root.right = right_rotate(root.right) unless root.right.left.nil?
    else
      root.right.right = splay(root.right.right, key)
      root = left_rotate(root)
    end
    root.right.nil? ? root : left_rotate(root)
  end
end

def insert_rec(root, key)
  return Node.new(key) if root.nil?
  root = splay(root, key)
  n = Node.new(key)
  if root.key > key
    n.right = root
    n.left = root.left
    root.left = nil
  else
    n.left = root
    n.right = root.right
    root.right = nil
  end
  n
end

def traverse(node, result)
  return if node.nil?
  traverse(node.left, result)
  result << node.key
  traverse(node.right, result)
end

def sort(arr)
  root = nil
  arr.each { |x| root = insert_rec(root, x) }
  result = []
  traverse(root, result)
  (0...arr.length).each { |i| arr[i] = result[i] }
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
