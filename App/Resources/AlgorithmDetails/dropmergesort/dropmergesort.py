RECENCY = 8
EARLY_OUT_TEST_AT = 4
EARLY_OUT_DISORDER_FRACTION = 0.6


INSERT_SORT_THRESHOLD = 24
NINTHER_THRESHOLD = 128
PARTIAL_INSERT_SORT_LIMIT = 8


def sort(arr):
    length = len(arr)
    if length < 2:
        return

    dropped = []
    num_dropped_in_a_row = 0
    read = 0
    write = 0
    iteration = 0
    early_out_stop = length // EARLY_OUT_TEST_AT

    while read < length:
        iteration += 1
        if (
            iteration == early_out_stop
            and len(dropped) > read * EARLY_OUT_DISORDER_FRACTION
        ):
            # Too disordered for the adaptive approach to be worth it: flush what's been
            # dropped so far back into the array and fall back to a plain full sort.
            for value in dropped:
                arr[write] = value
                write += 1
            dropped.clear()
            pdq_sort(arr, 0, length)
            return

        if write == 0 or arr[read] >= arr[write - 1]:
            # In order — keep it.
            arr[write] = arr[read]
            write += 1
            read += 1
            num_dropped_in_a_row = 0
        elif num_dropped_in_a_row == 0 and write >= 2 and arr[read] >= arr[write - 2]:
            # Quick undo: the element two back would have accepted this one just fine, so
            # drop the one right before it instead of the new element.
            dropped.append(arr[write - 1])
            arr[write - 1] = arr[read]
            read += 1
        elif num_dropped_in_a_row < RECENCY:
            dropped.append(arr[read])
            read += 1
            num_dropped_in_a_row += 1
        else:
            # Accepting something `num_dropped_in_a_row` elements back made every subsequent
            # element drop — that accept was a mistake. Undo it, and any other recently
            # accepted elements bigger than the dropped run's maximum.
            del dropped[len(dropped) - num_dropped_in_a_row :]
            read -= num_dropped_in_a_row

            num_backtracked = 1
            write -= 1

            max_of_dropped = read
            for i in range(read + 1, read + num_dropped_in_a_row + 1):
                max_of_dropped = max(max_of_dropped, arr[i])

            while write >= 1 and max_of_dropped < arr[write - 1]:
                write -= 1
                num_backtracked += 1

            for i in range(write, write + num_backtracked):
                dropped.append(arr[i])

            num_dropped_in_a_row = 0

    for offset, value in enumerate(dropped):
        arr[write + offset] = value

    pdq_sort(arr, write, length)

    # Copy the now-sorted dropped tail before the final backward merge starts overwriting
    # arr[write:] in place.
    buffer = arr[write : write + len(dropped)]

    i = len(buffer) - 1
    j = write - 1
    k = length - 1

    while i >= 0:
        if j < 0 or buffer[i] > arr[j]:
            arr[k] = buffer[i]
            k -= 1
            i -= 1
        else:
            arr[k] = arr[j]
            k -= 1
            j -= 1

def pdq_log(n):
    log = 0
    while True:
        n >>= 1
        if n == 0:
            break
        log += 1
    return log


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


def part_right(arr, begin, end):
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
    while first < last:
        arr[first], arr[last] = arr[last], arr[first]
        first += 1
        while arr[first] < pivot:
            first += 1
        last -= 1
        while not (arr[last] < pivot):
            last -= 1

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
                arr[begin + root], arr[begin + child] = (
                    arr[begin + child],
                    arr[begin + root],
                )
                root = child
            else:
                break

    for i in range(n // 2 - 1, -1, -1):
        sift_down(i, n)
    for i in range(n - 1, 0, -1):
        arr[begin], arr[begin + i] = arr[begin + i], arr[begin]
        sift_down(0, i)


def pdq_loop(arr, begin, end, bad_allowed):
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
            sort_three(
                arr, begin + half_size - 1, begin + half_size, begin + half_size + 1
            )
            arr[begin], arr[begin + half_size] = arr[begin + half_size], arr[begin]
        else:
            sort_three(arr, begin + half_size, begin, end - 1)

        if not leftmost and not (arr[begin - 1] < arr[begin]):
            begin = part_left(arr, begin, end) + 1
            continue

        pivot_pos, already_parted = part_right(arr, begin, end)

        left_size = pivot_pos - begin
        right_size = end - (pivot_pos + 1)
        high_unbalance = left_size < size // 8 or right_size < size // 8

        if high_unbalance:
            bad_allowed -= 1
            if bad_allowed == 0:
                heap_sort(arr, begin, end)
                return

            if left_size >= INSERT_SORT_THRESHOLD:
                arr[begin], arr[begin + left_size // 4] = (
                    arr[begin + left_size // 4],
                    arr[begin],
                )
                arr[pivot_pos - 1], arr[pivot_pos - left_size // 4] = (
                    arr[pivot_pos - left_size // 4],
                    arr[pivot_pos - 1],
                )
                if left_size > NINTHER_THRESHOLD:
                    arr[begin + 1], arr[begin + (left_size // 4 + 1)] = (
                        arr[begin + (left_size // 4 + 1)],
                        arr[begin + 1],
                    )
                    arr[begin + 2], arr[begin + (left_size // 4 + 2)] = (
                        arr[begin + (left_size // 4 + 2)],
                        arr[begin + 2],
                    )
                    arr[pivot_pos - 2], arr[pivot_pos - (left_size // 4 + 1)] = (
                        arr[pivot_pos - (left_size // 4 + 1)],
                        arr[pivot_pos - 2],
                    )
                    arr[pivot_pos - 3], arr[pivot_pos - (left_size // 4 + 2)] = (
                        arr[pivot_pos - (left_size // 4 + 2)],
                        arr[pivot_pos - 3],
                    )

            if right_size >= INSERT_SORT_THRESHOLD:
                arr[pivot_pos + 1], arr[pivot_pos + (1 + right_size // 4)] = (
                    arr[pivot_pos + (1 + right_size // 4)],
                    arr[pivot_pos + 1],
                )
                arr[end - 1], arr[end - right_size // 4] = (
                    arr[end - right_size // 4],
                    arr[end - 1],
                )
                if right_size > NINTHER_THRESHOLD:
                    arr[pivot_pos + 2], arr[pivot_pos + (2 + right_size // 4)] = (
                        arr[pivot_pos + (2 + right_size // 4)],
                        arr[pivot_pos + 2],
                    )
                    arr[pivot_pos + 3], arr[pivot_pos + (3 + right_size // 4)] = (
                        arr[pivot_pos + (3 + right_size // 4)],
                        arr[pivot_pos + 3],
                    )
                    arr[end - 2], arr[end - (1 + right_size // 4)] = (
                        arr[end - (1 + right_size // 4)],
                        arr[end - 2],
                    )
                    arr[end - 3], arr[end - (2 + right_size // 4)] = (
                        arr[end - (2 + right_size // 4)],
                        arr[end - 3],
                    )
        else:
            if (
                already_parted
                and partial_insert_sort(arr, begin, pivot_pos)
                and partial_insert_sort(arr, pivot_pos + 1, end)
            ):
                return

        pdq_loop(arr, begin, pivot_pos, bad_allowed)
        begin = pivot_pos + 1
        leftmost = False


def pdq_sort(arr, begin, end):
    if end - begin > 1:
        pdq_loop(arr, begin, end, pdq_log(end - begin))


if __name__ == "__main__":
    array = [
        0,
        1,
        2,
        3,
        4,
        9,
        6,
        7,
        8,
        5,
        10,
        11,
        12,
        13,
        14,
        15,
        21,
        17,
        18,
        19,
        20,
        16,
        22,
        23,
        24,
        28,
        26,
        27,
        25,
        29,
    ]
    sort(array)
    print(array)
