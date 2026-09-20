def sort(arr):
    n = len(arr)
    if n < 2:
        return
    gap, ratio = 14, 4
    positions = [0] * (gap + 2)
    heap = [0] * (gap + 2)
    state = 0x9E3779B97F4A7C15
    mask = (1 << 64) - 1
    for value in arr:
        state = (
            (state ^ (value & mask)) * 0xBF58476D1CE4E5B9 + 0x94D049BB133111EB
        ) & mask

    def random_choice(count):
        nonlocal state
        state ^= state >> 12
        state ^= (state << 25) & mask
        state ^= state >> 27
        return ((state * 0x2545F4914F6CDD1D) & mask) % count

    def swap(i, j):
        arr[i], arr[j] = arr[j], arr[i]

    def median(a, m, b):
        if arr[m] > arr[a]:
            if arr[m] < arr[b]:
                return m
            return a if arr[a] > arr[b] else b
        if arr[m] > arr[b]:
            return m
        return a if arr[a] < arr[b] else b

    def ninther(a, b):
        step = (b - a) // 9
        return median(
            median(a, a + step, a + 2 * step),
            median(a + 3 * step, a + 4 * step, a + 5 * step),
            median(a + 6 * step, a + 7 * step, a + 8 * step),
        )

    def pivot_index(a, b):
        step = (b - a) // 3
        return median(
            ninther(a, a + step),
            ninther(a + step, a + 2 * step),
            ninther(a + 2 * step, b),
        )

    def bin_search(a, b, val, backward):
        while a < b:
            m = a + (b - a) // 2
            found = arr[m] < val if backward else arr[m] > val
            if found:
                b = m
            else:
                a = m + 1
        return a

    def insert_to(value, start, end):
        while start > end:
            start -= 1
            arr[start + 1] = arr[start]
        arr[end] = value

    def binary_insertion(a, b):
        for i in range(a + 1, b):
            value = arr[i]
            insert_to(value, i, bin_search(a, i, value, False))

    def block_search(a, b, val, right):
        while a < b:
            m = a + ((b - a) // (gap + 1) // 2) * (gap + 1)
            found = arr[m] > val if right else arr[m] >= val
            if found:
                b = m
            else:
                a = m + gap + 1
        return a

    def retrieve(i, p, p_end, boundary_value, backward):
        j = i - 1
        k = p_end - (gap + 1)
        while k > p + gap:
            m = bin_search(k - gap, k, boundary_value, backward) - 1
            k -= gap + 1
            while m >= k:
                swap(j, m)
                j -= 1
                m -= 1
        m = bin_search(p, p + gap, boundary_value, backward) - 1
        while m >= p:
            swap(j, m)
            j -= 1
            m -= 1

    def library_sort(a, b, p, boundary_value, backward):
        length = b - a
        if length < 32:
            binary_insertion(a, b)
            return
        s = length
        while s >= 32:
            s = (s - 1) // ratio + 1
        i, j = a + s, a + ratio * s
        p_end = p + (s + 1) * (gap + 1) + gap
        binary_insertion(a, i)
        for k in range(s):
            swap(a + k, p + k * (gap + 1) + gap)
        while i < b:
            if i == j:
                retrieve(i, p, p_end, boundary_value, backward)
                s = i - a
                p_end = p + (s + 1) * (gap + 1) + gap
                j = a + (j - a) * ratio
                for k in range(s):
                    swap(a + k, p + k * (gap + 1) + gap)
            value = arr[i]
            block = block_search(p + gap, p_end - (gap + 1), value, False)
            if arr[block] == value:
                equal_end = block_search(
                    block + gap + 1, p_end - (gap + 1), value, True
                )
                block += random_choice((equal_end - block) // (gap + 1)) * (gap + 1)
            loc = bin_search(block - gap, block, boundary_value, backward)
            if loc == block:
                while True:
                    block += gap + 1
                    if (
                        block >= p_end
                        or bin_search(block - gap, block, boundary_value, backward)
                        != block
                    ):
                        break
                if block == p_end:
                    retrieve(i, p, p_end, boundary_value, backward)
                    s = i - a
                    p_end = p + (s + 1) * (gap + 1) + gap
                    j = a + (j - a) * ratio
                    for k in range(s):
                        swap(a + k, p + k * (gap + 1) + gap)
                else:
                    rot_p = bin_search(block - gap, block, boundary_value, backward)
                    rot_s = block - max(rot_p, block - gap // 2)
                    m, end = block - rot_s, block
                    while m > loc - rot_s:
                        m -= 1
                        end -= 1
                        swap(end, m)
            else:
                displaced = arr[loc]
                arr[i] = displaced
                i += 1
                insert_to(value, loc, bin_search(block - gap, loc, value, False))
        retrieve(b, p, p_end, boundary_value, backward)

    def merge(run_length, b, destination, run_count):
        if run_count < 2:
            if run_count == 1:
                while positions[0] < b:
                    swap(destination, positions[0])
                    destination += 1
                    positions[0] += 1
            return
        a = positions[0]
        for i in range(run_count):
            heap[i] = i

        def less(i, j):
            left, right = arr[positions[i]], arr[positions[j]]
            return left < right or (left == right and i < j)

        def sift(item, root, size):
            while 2 * root + 2 < size:
                left = 2 * root + 1
                child = left if less(heap[left], heap[left + 1]) else left + 1
                if less(heap[child], item):
                    heap[root] = heap[child]
                    root = child
                else:
                    break
            left = 2 * root + 1
            if left < size and less(heap[left], item):
                heap[root] = heap[left]
                root = left
            heap[root] = item

        for i in range((run_count - 1) // 2, -1, -1):
            sift(heap[i], i, run_count)
        size = run_count
        while size > 0:
            run = heap[0]
            swap(destination, positions[run])
            destination += 1
            positions[run] += 1
            if positions[run] == min(a + (run + 1) * run_length, b):
                size -= 1
                sift(heap[size], 0, size)
            else:
                sift(heap[0], 0, size)

    a, b = 0, n
    while b - a >= 32:
        pivot = arr[pivot_index(a, b)]
        first, i, j, last = a, a - 1, b, b
        while True:
            i += 1
            while i < j:
                if arr[i] == pivot:
                    swap(first, i)
                    first += 1
                elif arr[i] < pivot:
                    break
                i += 1
            j -= 1
            while j > i:
                if arr[j] == pivot:
                    last -= 1
                    swap(last, j)
                elif arr[j] > pivot:
                    break
                j -= 1
            if i < j:
                swap(i, j)
            else:
                if first == b:
                    return
                if j < i:
                    j += 1
                while first > a:
                    i -= 1
                    first -= 1
                    swap(i, first)
                while last < b:
                    swap(j, last)
                    j += 1
                    last += 1
                break
        left, right, run_count = i - a, b - j, 0
        if left <= right:
            m = b - left
            left = max((right + 1) // (gap + 1), 16)
            for k in range(a, i, left):
                library_sort(k, min(k + left, i), j, pivot, True)
                positions[run_count] = k
                run_count += 1
            merge(left, i, m, run_count)
            if j - i < m - j:
                while i < j:
                    m -= 1
                    swap(i, m)
                    i += 1
                b = m
            else:
                while m > j:
                    m -= 1
                    swap(i, m)
                    i += 1
                b = i
        else:
            m = a + right
            right = max((left + 1) // (gap + 1), 16)
            for k in range(j, b, right):
                library_sort(k, min(k + right, b), a, pivot, False)
                positions[run_count] = k
                run_count += 1
            merge(right, b, a, run_count)
            if i - m < j - i:
                while m < i:
                    j -= 1
                    swap(m, j)
                    m += 1
                a = j
            else:
                while j > i:
                    j -= 1
                    swap(m, j)
                    m += 1
                a = m
    binary_insertion(a, b)


if __name__ == "__main__":
    array = [
        0, 39, 21, 62, 91, 77, 14, 23,
        90, 69, 51, 81, 68, 83, 32, 56,
    ]
    sort(array)
    print(array)
