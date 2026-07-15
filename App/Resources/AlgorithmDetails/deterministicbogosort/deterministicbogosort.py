def sort(arr):
    n = len(arr)

    def is_sorted():
        return arr == sorted(arr)

    def permutation_sort(depth):
        if depth >= n - 1:
            return is_sorted()
        for i in range(n - 1, depth, -1):
            if permutation_sort(depth + 1):
                return True
            if (n - depth) % 2 == 0:
                arr[depth], arr[i] = arr[i], arr[depth]
            else:
                arr[depth], arr[n - 1] = arr[n - 1], arr[depth]
        return permutation_sort(depth + 1)

    permutation_sort(0)

array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
print(array)
