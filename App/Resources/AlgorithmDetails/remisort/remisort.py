def sort(arr):
    n = len(arr)
    if n < 2:
        return

    def ceil_cbrt(value):
        low, high = 0, min(1291, value)
        while low < high:
            mid = (low + high) // 2
            if mid * mid * mid >= value:
                high = mid
            else:
                low = mid + 1
        return low

    block_len = ceil_cbrt(n)
    run_len = block_len * block_len
    run_count = (n - 1) // run_len + 1
    keys = list(range(n if run_count < 2 else run_len))

    def greater(a, b, base):
        return arr[base + a] > arr[base + b] or (
            arr[base + a] == arr[base + b] and a > b
        )

    def table_sift(root, length, base, item):
        j = root
        while 2 * j + 1 < length:
            j = 2 * j + 1
            if j + 1 < length and greater(keys[j + 1], keys[j], base):
                j += 1
        while j > root and greater(item, keys[j], base):
            j = (j - 1) // 2
        while j > root:
            item, keys[j] = keys[j], item
            j = (j - 1) // 2
        keys[root] = item

    def table_sort(start, end):
        length = end - start
        if length < 2:
            return
        for i in range((length - 1) // 2, -1, -1):
            table_sift(i, length, start, keys[i])
        for i in range(length - 1, 0, -1):
            item = keys[i]
            keys[i] = keys[0]
            table_sift(0, i, start, item)
        for i in range(length):
            if keys[i] != i:
                held = arr[start + i]
                j, nxt = i, keys[i]
                while True:
                    arr[start + j] = arr[start + nxt]
                    keys[j] = j
                    j, nxt = nxt, keys[nxt]
                    if nxt == i:
                        break
                arr[start + j] = held
                keys[j] = j

    if run_count < 2:
        table_sort(0, n)
        return

    buffer = [0] * run_len
    heap = list(range(run_count))
    positions = [0] * run_count
    destinations = [0] * run_count
    for run in range(run_count):
        start = run * run_len
        table_sort(start, min(start + run_len, n))
        positions[run] = destinations[run] = start

    def less(a, b):
        left, right = arr[positions[a]], arr[positions[b]]
        return left < right or (left == right and a < b)

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

    def advance(run):
        nonlocal size
        positions[run] += 1
        if positions[run] == min((run + 1) * run_len, n):
            size -= 1
            sift(heap[size], 0, size)
        else:
            sift(heap[0], 0, size)

    for i in range(run_len):
        run = heap[0]
        buffer[i] = arr[positions[run]]
        advance(run)

    t = count = cursor = 0
    while positions[cursor] - destinations[cursor] < block_len:
        cursor += 1
    while True:
        run = heap[0]
        arr[destinations[cursor]] = arr[positions[run]]
        positions[run] += 1
        destinations[cursor] += 1
        if positions[run] == min((run + 1) * run_len, n):
            size -= 1
            sift(heap[size], 0, size)
        else:
            sift(heap[0], 0, size)
        count += 1
        if count == block_len:
            keys[t] = (
                destinations[cursor] // block_len - block_len - 1 if cursor > 0 else -1
            )
            t += 1
            cursor = count = 0
            while positions[cursor] - destinations[cursor] < block_len:
                cursor += 1
        if size == 0:
            break

    end = n
    while count > 0:
        count -= 1
        destinations[cursor] -= 1
        end -= 1
        arr[end] = arr[destinations[cursor]]
    positions[-1] = end
    keys[-1] = -1
    t = 0
    while keys[t] != -1:
        t += 1
    source = 0
    for i in range(1, run_count):
        if source >= destinations[0]:
            break
        while destinations[i] < positions[i]:
            keys[t] = destinations[i] // block_len - block_len
            t += 1
            while keys[t] != -1:
                t += 1
            for x in range(block_len):
                arr[destinations[i] + x] = arr[source + x]
            destinations[i] += block_len
            source += block_len
    arr[:run_len] = buffer
    block_count = (end - run_len) // block_len
    for i in range(block_count):
        if keys[i] != i:
            buffer[:block_len] = arr[
                run_len + i * block_len : run_len + (i + 1) * block_len
            ]
            j, nxt = i, keys[i]
            while True:
                for x in range(block_len):
                    arr[run_len + j * block_len + x] = arr[
                        run_len + nxt * block_len + x
                    ]
                keys[j] = j
                j, nxt = nxt, keys[nxt]
                if nxt == i:
                    break
            for x in range(block_len):
                arr[run_len + j * block_len + x] = buffer[x]
            keys[j] = j


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
