def sort(arr)
  n = arr.length()

  height = lambda do |node|
    count = 0
    while (node >> count) % 2 == 1
      count += 1
    end
    count
  end

  thrift = lambda do |node, parent_flag, root_flag|
    is_root = root_flag && (node >= (1 << height.call(node)))
    if !is_root && !parent_flag
      next
    end

    choice = height.call(node) - (is_root ? 0 : 1)
    if parent_flag
      (choice - 1).downto(0) do |child|
        if arr[node - (1 << choice)] <= arr[node - (1 << child)]
          choice = child
        end
      end
    end

    if arr[node - (1 << choice)] <= arr[node]
      next
    end

    arr[node], arr[node - (1 << choice)] = arr[node - (1 << choice)], arr[node]
    next_node = node - (1 << choice)
    thrift.call(next_node, next_node % 2 == 1, choice == height.call(node))
  end

  node = 1
  while node < n
    thrift.call(node, node % 2 == 1, (node + (1 << height.call(node))) >= n)
    node += 1
  end

  node -= (node - 1) % 2
  while node > 2
    (height.call(node) - 1).downto(0) do |child|
      thrift.call(node - (1 << child), false, true)
    end
    node -= 2
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
