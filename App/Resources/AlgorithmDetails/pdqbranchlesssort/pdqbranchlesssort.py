INSERT_SORT_THRESHOLD = 24
NINTHER_THRESHOLD = 128
PARTIAL_INSERT_SORT_LIMIT = 8
BLOCK_SIZE = 64
CACHELINE_SIZE = 64


def pdq_log(n):
    log = 0
    while True:
        n >>= 1
        if n == 0:
            break
        log += 1
    return log


def trunc_div(a, b):
    # Integer division truncated toward zero. Python's `//` floors toward negative
    # infinity, but the pivot-position arithmetic below can go negative, so plain
    # `//` would silently disagree with C/Java/Swift/etc. semantics in that case.
    q = abs(a) // abs(b)
    return -q if (a < 0) != (b < 0) else q


def insert_sort(arr, begin, end):
    for cur in range(begin + 1, end):
        if arr[cur] < arr[cur - 1]:
            tmp = arr[cur]
            sift = cur
            sift_minus_one = cur - 1
            while True:
                arr[sift] = arr[sift_minus_one]
                sift -= 1
                sift_minus_one -= 1
                if sift == begin or not (tmp < arr[sift_minus_one]):
                    break
            arr[sift] = tmp


def unguard_insert_sort(arr, begin, end):
    for cur in range(begin + 1, end):
        if arr[cur] < arr[cur - 1]:
            tmp = arr[cur]
            sift = cur
            sift_minus_one = cur - 1
            while True:
                arr[sift] = arr[sift_minus_one]
                sift -= 1
                sift_minus_one -= 1
                if not (tmp < arr[sift_minus_one]):
                    break
            arr[sift] = tmp


def partial_insert_sort(arr, begin, end):
    limit = 0
    for cur in range(begin + 1, end):
        if limit > PARTIAL_INSERT_SORT_LIMIT:
            return False
        if arr[cur] < arr[cur - 1]:
            tmp = arr[cur]
            sift = cur
            sift_minus_one = cur - 1
            while True:
                arr[sift] = arr[sift_minus_one]
                sift -= 1
                sift_minus_one -= 1
                if sift == begin or not (tmp < arr[sift_minus_one]):
                    break
            arr[sift] = tmp
            limit += cur - sift
    return True


def sort_two(arr, a, b):
    if arr[b] < arr[a]:
        arr[a], arr[b] = arr[b], arr[a]


def sort_three(arr, a, b, c):
    sort_two(arr, a, b)
    sort_two(arr, b, c)
    sort_two(arr, a, b)


def swap_offsets(arr, first, last, left_offsets, left_pos, right_offsets, right_pos, num, use_swaps):
    if use_swaps:
        for i in range(num):
            li = first + left_offsets[left_pos + i]
            ri = last - right_offsets[right_pos + i]
            arr[li], arr[ri] = arr[ri], arr[li]
    elif num > 0:
        left = first + left_offsets[left_pos]
        right = last - right_offsets[right_pos]
        tmp = arr[left]
        arr[left] = arr[right]
        for i in range(1, num):
            left = first + left_offsets[left_pos + i]
            arr[right] = arr[left]
            right = last - right_offsets[right_pos + i]
            arr[left] = arr[right]
        arr[right] = tmp


def part_right_branchless(arr, begin, end, left_offsets, right_offsets):
    pivot = arr[begin]
    first = begin
    last = end

    first += 1
    while arr[first] < pivot:
        first += 1

    if first - 1 == begin:
        last -= 1
        while first < last and not (arr[last] < pivot):
            last -= 1
    else:
        last -= 1
        while not (arr[last] < pivot):
            last -= 1

    already_parted = first >= last
    if not already_parted:
        arr[first], arr[last] = arr[last], arr[first]
        first += 1

    left_num = 0
    right_num = 0
    left_start = 0
    right_start = 0

    while last - first > 2 * BLOCK_SIZE:
        if left_num == 0:
            left_start = 0
            it = first
            for i in range(BLOCK_SIZE):
                left_offsets[left_num] = i
                if not (arr[it] < pivot):
                    left_num += 1
                it += 1
        if right_num == 0:
            right_start = 0
            it = last
            for i in range(BLOCK_SIZE):
                it -= 1
                right_offsets[right_num] = i + 1
                if arr[it] < pivot:
                    right_num += 1

        num = min(left_num, right_num)
        swap_offsets(arr, first, last, left_offsets, left_start, right_offsets, right_start, num, left_num == right_num)
        left_num -= num
        right_num -= num
        left_start += num
        right_start += num
        if left_num == 0:
            first += BLOCK_SIZE
        if right_num == 0:
            last -= BLOCK_SIZE

    left_size = 0
    right_size = 0
    unknown_left = (last - first) - (BLOCK_SIZE if (right_num != 0 or left_num != 0) else 0)
    if right_num != 0:
        left_size = unknown_left
        right_size = BLOCK_SIZE
    elif left_num != 0:
        left_size = BLOCK_SIZE
        right_size = unknown_left
    else:
        left_size = trunc_div(unknown_left, 2)
        right_size = unknown_left - left_size

    if unknown_left != 0 and left_num == 0:
        left_start = 0
        it = first
        for i in range(left_size):
            left_offsets[left_num] = i
            if not (arr[it] < pivot):
                left_num += 1
            it += 1

    if unknown_left != 0 and right_num == 0:
        right_start = 0
        it = last
        for i in range(right_size):
            it -= 1
            right_offsets[right_num] = i + 1
            if arr[it] < pivot:
                right_num += 1

    num = min(left_num, right_num)
    swap_offsets(arr, first, last, left_offsets, left_start, right_offsets, right_start, num, left_num == right_num)
    left_num -= num
    right_num -= num
    left_start += num
    right_start += num
    if left_num == 0:
        first += left_size
    if right_num == 0:
        last -= right_size

    left_offsets_pos = 0
    right_offsets_pos = 0

    if left_num != 0:
        left_offsets_pos += left_start
        while left_num != 0:
            left_num -= 1
            last -= 1
            src = first + left_offsets[left_offsets_pos + left_num]
            arr[src], arr[last] = arr[last], arr[src]
        first = last

    if right_num != 0:
        right_offsets_pos += right_start
        while right_num != 0:
            right_num -= 1
            src = last - right_offsets[right_offsets_pos + right_num]
            arr[src], arr[first] = arr[first], arr[src]
            first += 1
        last = first

    pivot_pos = first - 1
    arr[begin] = arr[pivot_pos]
    arr[pivot_pos] = pivot

    return pivot_pos, already_parted


def part_left(arr, begin, end):
    pivot = arr[begin]
    first = begin
    last = end

    last -= 1
    while pivot < arr[last]:
        last -= 1

    if last + 1 == end:
        first += 1
        while first < last and not (pivot < arr[first]):
            first += 1
    else:
        first += 1
        while not (pivot < arr[first]):
            first += 1

    while first < last:
        arr[first], arr[last] = arr[last], arr[first]
        last -= 1
        while pivot < arr[last]:
            last -= 1
        first += 1
        while not (pivot < arr[first]):
            first += 1

    pivot_pos = last
    arr[begin] = arr[pivot_pos]
    arr[pivot_pos] = pivot
    return pivot_pos


def heap_sort(arr, begin, end):
    n = end - begin

    def sift_down(root, size):
        while True:
            child = 2 * root + 1
            if child >= size:
                break
            if child + 1 < size and arr[begin + child] < arr[begin + child + 1]:
                child += 1
            if arr[begin + root] < arr[begin + child]:
                arr[begin + root], arr[begin + child] = arr[begin + child], arr[begin + root]
                root = child
            else:
                break

    for i in range(n // 2 - 1, -1, -1):
        sift_down(i, n)
    for i in range(n - 1, 0, -1):
        arr[begin], arr[begin + i] = arr[begin + i], arr[begin]
        sift_down(0, i)


def pdq_loop(arr, begin, end, bad_allowed, left_offsets, right_offsets):
    leftmost = True
    while True:
        size = end - begin

        if size < INSERT_SORT_THRESHOLD:
            if leftmost:
                insert_sort(arr, begin, end)
            else:
                unguard_insert_sort(arr, begin, end)
            return

        half_size = size // 2
        if size > NINTHER_THRESHOLD:
            sort_three(arr, begin, begin + half_size, end - 1)
            sort_three(arr, begin + 1, begin + half_size - 1, end - 2)
            sort_three(arr, begin + 2, begin + half_size + 1, end - 3)
            sort_three(arr, begin + half_size - 1, begin + half_size, begin + half_size + 1)
            arr[begin], arr[begin + half_size] = arr[begin + half_size], arr[begin]
        else:
            sort_three(arr, begin + half_size, begin, end - 1)

        if not leftmost and not (arr[begin - 1] < arr[begin]):
            begin = part_left(arr, begin, end) + 1
            continue

        pivot_pos, already_parted = part_right_branchless(arr, begin, end, left_offsets, right_offsets)

        left_size = pivot_pos - begin
        right_size = end - (pivot_pos + 1)
        high_unbalance = left_size < size // 8 or right_size < size // 8

        if high_unbalance:
            bad_allowed -= 1
            if bad_allowed == 0:
                heap_sort(arr, begin, end)
                return

            if left_size >= INSERT_SORT_THRESHOLD:
                arr[begin], arr[begin + left_size // 4] = arr[begin + left_size // 4], arr[begin]
                arr[pivot_pos - 1], arr[pivot_pos - left_size // 4] = arr[pivot_pos - left_size // 4], arr[pivot_pos - 1]
                if left_size > NINTHER_THRESHOLD:
                    arr[begin + 1], arr[begin + (left_size // 4 + 1)] = arr[begin + (left_size // 4 + 1)], arr[begin + 1]
                    arr[begin + 2], arr[begin + (left_size // 4 + 2)] = arr[begin + (left_size // 4 + 2)], arr[begin + 2]
                    arr[pivot_pos - 2], arr[pivot_pos - (left_size // 4 + 1)] = arr[pivot_pos - (left_size // 4 + 1)], arr[pivot_pos - 2]
                    arr[pivot_pos - 3], arr[pivot_pos - (left_size // 4 + 2)] = arr[pivot_pos - (left_size // 4 + 2)], arr[pivot_pos - 3]

            if right_size >= INSERT_SORT_THRESHOLD:
                arr[pivot_pos + 1], arr[pivot_pos + (1 + right_size // 4)] = arr[pivot_pos + (1 + right_size // 4)], arr[pivot_pos + 1]
                arr[end - 1], arr[end - right_size // 4] = arr[end - right_size // 4], arr[end - 1]
                if right_size > NINTHER_THRESHOLD:
                    arr[pivot_pos + 2], arr[pivot_pos + (2 + right_size // 4)] = arr[pivot_pos + (2 + right_size // 4)], arr[pivot_pos + 2]
                    arr[pivot_pos + 3], arr[pivot_pos + (3 + right_size // 4)] = arr[pivot_pos + (3 + right_size // 4)], arr[pivot_pos + 3]
                    arr[end - 2], arr[end - (1 + right_size // 4)] = arr[end - (1 + right_size // 4)], arr[end - 2]
                    arr[end - 3], arr[end - (2 + right_size // 4)] = arr[end - (2 + right_size // 4)], arr[end - 3]
        else:
            if already_parted and partial_insert_sort(arr, begin, pivot_pos) and partial_insert_sort(arr, pivot_pos + 1, end):
                return

        pdq_loop(arr, begin, pivot_pos, bad_allowed, left_offsets, right_offsets)
        begin = pivot_pos + 1
        leftmost = False


def sort(arr):
    n = len(arr)
    if n < 2:
        return
    left_offsets = [0] * (BLOCK_SIZE + CACHELINE_SIZE)
    right_offsets = [0] * (BLOCK_SIZE + CACHELINE_SIZE)
    pdq_loop(arr, 0, n, pdq_log(n), left_offsets, right_offsets)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
