def sort(arr):
    n = len(arr)

    def height(node):
        count = 0
        while (node >> count) % 2 == 1:
            count += 1
        return count

    def thrift(node, parent_flag, root_flag):
        is_root = root_flag and (node >= (1 << height(node)))
        if not is_root and not parent_flag:
            return

        choice = height(node) - (0 if is_root else 1)
        if parent_flag:
            for child in range(choice - 1, -1, -1):
                if arr[node - (1 << choice)] <= arr[node - (1 << child)]:
                    choice = child

        if arr[node - (1 << choice)] <= arr[node]:
            return

        arr[node], arr[node - (1 << choice)] = arr[node - (1 << choice)], arr[node]
        next_node = node - (1 << choice)
        thrift(next_node, next_node % 2 == 1, choice == height(node))

    node = 1
    while node < n:
        thrift(node, node % 2 == 1, (node + (1 << height(node))) >= n)
        node += 1

    node -= (node - 1) % 2
    while node > 2:
        for child in range(height(node) - 1, -1, -1):
            thrift(node - (1 << child), False, True)
        node -= 2


array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
print(array)
