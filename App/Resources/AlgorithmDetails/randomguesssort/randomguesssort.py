def sort(arr):
    n = len(arr)
    if n <= 1:
        return
    loops = [0] * n
    while True:
        is_sorted = True
        for i in range(n - 1):
            a, b = arr[loops[i]], arr[loops[i + 1]]
            if a < b or (a == b and loops[i] < loops[i + 1]):
                continue
            is_sorted = False
            break
        if is_sorted:
            break
        for pos in range(n):
            if loops[pos] < n - 1:
                loops[pos] += 1
                break
            loops[pos] = 0

    mapped = [arr[i] for i in loops]
    for i in range(n):
        arr[i] = mapped[i]


if __name__ == "__main__":
    array = [0, 39, 21, 62, 14]
    sort(array)
    print(array)
