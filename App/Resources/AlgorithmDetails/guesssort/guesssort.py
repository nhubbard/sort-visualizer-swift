def sort(arr):
    n = len(arr)
    loops = [0] * n
    indexes = [0] * n

    def is_valid():
        total = 0
        for i in range(n):
            for j in range(n):
                if loops[i] == loops[j]:
                    total += 1
        for i in range(n):
            for j in range(n):
                if i < j and arr[loops[i]] > arr[loops[j]]:
                    total += 1
                elif i > j and arr[loops[i]] < arr[loops[j]]:
                    total += 1
        return total == n

    while True:
        if is_valid():
            indexes[:] = loops
        pos = 0
        while pos < n:
            if loops[pos] < n - 1:
                loops[pos] += 1
                break
            else:
                loops[pos] = 0
                pos += 1
        if pos == n:
            break

    original = arr[:]
    for i in range(n):
        arr[i] = original[indexes[i]]


array = [0, 39, 21, 14]
sort(array)
print(array)
