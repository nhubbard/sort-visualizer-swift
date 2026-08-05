def ceil_pow2(value):
    r = 1
    while r < value:
        r *= 2
    return r


def sort(array):
    n = len(array)
    if n <= 1:
        return

    size = ceil_pow2(n) - 1
    mod = n % 2
    tree_size = n + size + mod
    tree = [-1] * tree_size

    def tree_compare(a, b):
        return array[tree[a]] <= array[tree[b]]

    for i in range(size, tree_size - mod):
        tree[i] = i - size

    j = size
    k = tree_size - mod
    while j > 0:
        i = j
        while i + 1 < k:
            tree[i // 2] = tree[i] if tree_compare(i, i + 1) else tree[i + 1]
            i += 2
        if i < k:
            tree[i // 2] = tree[i]
        j //= 2
        k //= 2

    def find_next():
        path = tree[0] + size
        while path > 0:
            tree[path] = -1
            path = (path - 1) // 2

        node = tree[0] + size
        while node > 0:
            sibling = node + 1 if node % 2 == 1 else node - 1
            node_valid = tree[node] != -1
            sibling_valid = tree[sibling] != -1
            if node_valid and sibling_valid:
                if node < sibling:
                    winner = (
                        tree[node] if tree_compare(node, sibling) else tree[sibling]
                    )
                else:
                    winner = (
                        tree[sibling] if tree_compare(sibling, node) else tree[node]
                    )
            elif node_valid:
                winner = tree[node]
            elif sibling_valid:
                winner = tree[sibling]
            else:
                winner = -1
            node = (node - 1) // 2
            if winner != -1:
                tree[node] = winner
        return array[tree[0]]

    output = [0] * n
    output[0] = array[tree[0]]
    for i in range(1, n):
        output[i] = find_next()
    array[:] = output


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
