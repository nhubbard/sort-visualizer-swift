import random

def sort(arr):
    n = len(arr)
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
            loops[pos] = random.randint(0, n - 1)

    mapped = [arr[i] for i in loops]
    for i in range(n):
        arr[i] = mapped[i]

array = [0, 39, 21, 62, 14]
sort(array)
print(array)
