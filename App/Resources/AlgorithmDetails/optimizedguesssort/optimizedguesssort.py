def sort(arr):
    n = len(arr)
    loops = [0] * n

    def is_valid():
        for i in range(n - 1):
            a, b = arr[loops[i]], arr[loops[i + 1]]
            if a < b or (a == b and loops[i] < loops[i + 1]):
                continue
            return False
        return True

    while not is_valid():
        for pos in range(n):
            if loops[pos] < n - 1:
                loops[pos] += 1
                break
            else:
                loops[pos] = 0

    mapped = [arr[i] for i in loops]
    for i in range(n):
        arr[i] = mapped[i]

array = [0, 39, 21, 62, 14]
sort(array)
print(array)
