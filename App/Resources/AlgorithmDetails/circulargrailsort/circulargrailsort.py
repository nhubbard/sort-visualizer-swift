def sort(arr):
    n = len(arr)
    if n < 2:
        return

    def swap(a, b):
        a %= n
        b %= n
        arr[a], arr[b] = arr[b], arr[a]

    def shift_fw(a, m, b):
        while m < b:
            swap(a, m)
            a += 1
            m += 1

    def shift_bw(a, m, b):
        while m > a:
            b -= 1
            m -= 1
            swap(b, m)

    def insertion(a, b):
        for start in range(a + 1, b):
            i = start
            while i > a and arr[(i - 1) % n] > arr[i % n]:
                swap(i, i - 1)
                i -= 1

    def multi_swap(a, b, length):
        for offset in range(length):
            swap(a + offset, b + offset)

    def rotate(a, m, b):
        left, right = m - a, b - m
        while left and right:
            if right < left:
                multi_swap(m - right, m, right)
                b -= right
                m -= right
                left -= right
            else:
                multi_swap(a, m, left)
                a += left
                m += left
                right -= left

    def in_place_merge(a, m, b):
        i = a
        while i < m < b:
            if arr[i % n] > arr[m % n]:
                k = m + 1
                while k < b and arr[i % n] > arr[k % n]:
                    k += 1
                rotate(i, m, k)
                i += k - m
                m = k
            else:
                i += 1

    def merge(p, a, m, b, full):
        i, j = a, m
        while i < m and j < b:
            if arr[i % n] <= arr[j % n]:
                swap(p, i)
                i += 1
            else:
                swap(p, j)
                j += 1
            p += 1
        if i < m:
            if i > p:
                shift_fw(p, i, m)
        elif full:
            shift_fw(p, j, b)
        return i if i < m else j

    def block_less(a, b, block):
        if arr[a % n] != arr[b % n]:
            return arr[a % n] < arr[b % n]
        return arr[(a + block - 1) % n] < arr[(b + block - 1) % n]

    def block_merge(a, m, b, block):
        b1 = b - (b - m - 1) % block - 1
        if b1 <= m:
            merge(a - block, a, m, b, True)
            return
        b2 = b1
        i = m - block
        while i > a and block_less(b1, i, block):
            i -= block
            b2 -= block
        for j in range(a, b1 - block, block):
            minimum = j
            for candidate in range(j + block, b1, block):
                if block_less(candidate, minimum, block):
                    minimum = candidate
            if minimum != j:
                multi_swap(j, minimum, block)
        frontier = a
        for nxt in range(a + block, b2, block):
            frontier = merge(frontier - block, frontier, nxt, nxt + block, False)
            if frontier < nxt:
                shift_bw(frontier, nxt, nxt + block)
                frontier += block
        merge(frontier - block, frontier, b1, b, True)

    if n <= 16:
        insertion(0, n)
        return
    block = 1
    while block * block < n:
        block *= 2
    i, run, rolling, end = block, 1, n - block, n
    while run <= block:
        while i + 2 * run < end:
            merge(i - run, i, i + run, i + 2 * run, True)
            i += 2 * run
        if i + run < end:
            merge(i - run, i, i + run, end, True)
        else:
            shift_fw(i - run, i, end)
        i = end + block - run
        end = i + rolling
        run *= 2
    while run < rolling:
        while i + 2 * run < end:
            block_merge(i, i + run, i + 2 * run, block)
            i += 2 * run
        if i + run < end:
            block_merge(i, i + run, end, block)
        else:
            shift_fw(i - block, i, end)
        i = end
        end += rolling
        run *= 2
    insertion(i - block, i)
    in_place_merge(i - block, i, end)
    rotate(0, (i - block) % n, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
