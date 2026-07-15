def sort(arr):
    n = len(arr)

    def idx(p):
        return n - p

    def sift_down(root, dist):
        while root <= dist // 2:
            leaf = 2 * root
            if leaf < dist and arr[idx(leaf)] > arr[idx(leaf + 1)]:
                leaf += 1
            if arr[idx(root)] > arr[idx(leaf)]:
                arr[idx(root)], arr[idx(leaf)] = arr[idx(leaf)], arr[idx(root)]
                root = leaf
            else:
                break

    i = n // 2
    while i >= 1:
        sift_down(i, n)
        i -= 1

    i = n
    while i > 1:
        arr[idx(1)], arr[idx(i)] = arr[idx(i)], arr[idx(1)]
        sift_down(1, i - 1)
        i -= 1

array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
print(array)
