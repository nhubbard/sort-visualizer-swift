def reverse_run(arr, lo, hi):
    while lo < hi:
        arr[lo], arr[hi] = arr[hi], arr[lo]
        lo += 1
        hi -= 1


def identify_run(arr, index_in, n):
    # Finds the maximal run starting at index_in (every adjacent step in the
    # same direction), reversing it in place if that direction was
    # descending. Returns the index where the next run starts, or -1 if this
    # was the last run.
    if index_in >= n - 1:
        return -1
    start_index = index_in
    index = index_in
    ascending = arr[index] <= arr[index + 1]
    index += 1
    while index < n - 1:
        step_ascending = arr[index] <= arr[index + 1]
        if step_ascending != ascending:
            break
        index += 1
    if not ascending:
        reverse_run(arr, start_index, index)
    return -1 if index >= n - 1 else index + 1


def merge_up(arr, start, mid, end, buffer):
    # Merges arr[start:mid] with arr[mid:end] by copying the left run into a
    # scratch buffer and merging forward from the low end.
    for i in range(mid - start):
        buffer[i] = arr[start + i]
    buffer_pointer = 0
    left = start
    right = mid
    while left < right < end:
        if buffer[buffer_pointer] <= arr[right]:
            arr[left] = buffer[buffer_pointer]
            buffer_pointer += 1
        else:
            arr[left] = arr[right]
            right += 1
        left += 1
    while left < right:
        arr[left] = buffer[buffer_pointer]
        buffer_pointer += 1
        left += 1


def merge_down(arr, start, mid, end, buffer):
    # Merges arr[start:mid] with arr[mid:end] by copying the right run into a
    # scratch buffer and merging backward from the high end.
    for i in range(end - mid):
        buffer[i] = arr[mid + i]
    buffer_pointer = end - mid - 1
    left = mid - 1
    right = end - 1
    while right > left >= start:
        if buffer[buffer_pointer] >= arr[left]:
            arr[right] = buffer[buffer_pointer]
            buffer_pointer -= 1
        else:
            arr[right] = arr[left]
            left -= 1
        right -= 1
    while right > left:
        arr[right] = buffer[buffer_pointer]
        buffer_pointer -= 1
        right -= 1


def merge_runs(arr, left_start, right_start, end, buffer):
    # Picks whichever of merge_up/merge_down needs the smaller scratch copy.
    if end - right_start < right_start - left_start:
        merge_down(arr, left_start, right_start, end, buffer)
    else:
        merge_up(arr, left_start, right_start, end, buffer)


def sort(arr):
    n = len(arr)
    if n < 2:
        return

    runs = []
    last_run = 0
    while last_run != -1:
        runs.append(last_run)
        last_run = identify_run(arr, last_run, n)

    buffer = [0] * n
    run_count = len(runs)
    while run_count > 1:
        i = 0
        while i < run_count - 1:
            end = n if i + 2 >= run_count else runs[i + 2]
            merge_runs(arr, runs[i], runs[i + 1], end, buffer)
            i += 2

        runs = runs[0:run_count:2]
        run_count = len(runs)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
