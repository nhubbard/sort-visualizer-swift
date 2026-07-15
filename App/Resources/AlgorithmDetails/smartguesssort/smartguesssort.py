def sort(arr):
    n = len(arr)
    loops = [0] * n

    def pair_ok(i):
        a, b = arr[loops[i]], arr[loops[i + 1]]
        if a < b:
            return True
        if a == b and loops[i] < loops[i + 1]:
            return True
        return False

    def first_failure():
        i = n - 2
        while i >= 0 and pair_ok(i):
            i -= 1
        return i

    while True:
        i = first_failure()
        if i < 0:
            break
        for pos in range(n):
            if pos >= i and loops[pos] < n - 1:
                loops[pos] += 1
                break
            else:
                loops[pos] = 0

    mapped = [arr[i] for i in loops]
    for i in range(n):
        arr[i] = mapped[i]

array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
print(array)
