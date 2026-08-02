def sort(arr):
    n = len(arr)

    def comp_swap(a, b):
        if arr[a] > arr[b]:
            arr[a], arr[b] = arr[b], arr[a]

    max_ = 1
    while max_ * 2 < n:
        max_ *= 2

    next_ = max_
    while next_ > 0:
        i = 0
        while i + 1 < n:
            comp_swap(i, i + 1)
            i += 2

        j = max_
        while j >= next_ and j > 1:
            i = 1
            while i + j - 1 < n:
                comp_swap(i, i + j - 1)
                i += 2
            j //= 2

        next_ //= 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
