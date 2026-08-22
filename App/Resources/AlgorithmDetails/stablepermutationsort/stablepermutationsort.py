def sort(arr):
    n = len(arr)
    idx = list(range(n))

    def permute(length):
        if length < 2:
            return arr == sorted(arr)
        for i in range(length - 2, -1, -1):
            if permute(length - 1):
                return True
            arr[idx[i]], arr[idx[length - 1]] = arr[idx[length - 1]], arr[idx[i]]
            idx[i], idx[length - 1] = idx[length - 1], idx[i]
        if permute(length - 1):
            return True
        t = idx[length - 1]
        for i in range(length - 1, 0, -1):
            idx[i] = idx[i - 1]
        idx[0] = t
        t = arr[idx[0]]
        for i in range(1, length):
            arr[idx[i - 1]] = arr[idx[i]]
        arr[idx[length - 1]] = t
        return False

    permute(n)


array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
print(array)
