def swap(arr, a, b):
    arr[a], arr[b] = arr[b], arr[a]


def multi_swap(arr, a, b, count):
    for i in range(count):
        swap(arr, a + i, b + i)


def rotate(arr, pos, len_a, len_b):
    while len_a != 0 and len_b != 0:
        if len_a <= len_b:
            multi_swap(arr, pos, pos + len_a, len_a)
            pos += len_a
            len_b -= len_a
        else:
            multi_swap(arr, pos + (len_a - len_b), pos + len_a, len_b)
            len_a -= len_b


def insert_sort(arr, pos, length):
    for i in range(1, length):
        j = pos + i
        while j > pos and arr[j] < arr[j - 1]:
            swap(arr, j, j - 1)
            j -= 1


def bin_search(arr, pos, length, key_pos, is_left):
    left = -1
    right = length
    key = arr[key_pos]
    while left < right - 1:
        mid = left + (right - left) // 2
        cond = arr[pos + mid] >= key if is_left else arr[pos + mid] > key
        if cond:
            right = mid
        else:
            left = mid
    return right


def merge_without_buffer(arr, pos, len1, len2):
    if len1 == 0 or len2 == 0:
        return
    if len1 + len2 == 2:
        if arr[pos] > arr[pos + 1]:
            swap(arr, pos, pos + 1)
        return
    if len1 > len2:
        mid1 = len1 // 2
        mid2 = bin_search(arr, pos + len1, len2, pos + mid1, True)
    else:
        mid2 = len2 // 2
        mid1 = bin_search(arr, pos, len1, pos + len1 + mid2, False)
    rotate(arr, pos + mid1, len1 - mid1, mid2)
    merge_without_buffer(arr, pos, mid1, mid2)
    merge_without_buffer(arr, pos + mid1 + mid2, len1 - mid1, len2 - mid2)


def merge_left(arr, pos, left_len, right_len, dist):
    left = 0
    right = left_len
    right_len += left_len
    while right < right_len:
        if left == left_len or arr[pos + left] > arr[pos + right]:
            swap(arr, pos + dist, pos + right)
            dist += 1
            right += 1
        else:
            swap(arr, pos + dist, pos + left)
            dist += 1
            left += 1
    if dist != left:
        multi_swap(arr, pos + dist, pos + left, left_len - left)


def merge_right(arr, pos, left_len, right_len, dist):
    merged_pos = left_len + right_len + dist - 1
    right = left_len + right_len - 1
    left = left_len - 1
    while left >= 0:
        if right < left_len or arr[pos + left] > arr[pos + right]:
            swap(arr, pos + merged_pos, pos + left)
            merged_pos -= 1
            left -= 1
        else:
            swap(arr, pos + merged_pos, pos + right)
            merged_pos -= 1
            right -= 1
    while right != merged_pos and right >= left_len:
        swap(arr, pos + merged_pos, pos + right)
        merged_pos -= 1
        right -= 1


def smart_merge_with_buffer(arr, pos, left_over_len, block_len):
    dist = -block_len
    left = 0
    right = left_over_len
    left_end = right
    right_end = right + block_len
    while left < left_end and right < right_end:
        if arr[pos + left] <= arr[pos + right]:
            swap(arr, pos + dist, pos + left)
            dist += 1
            left += 1
        else:
            swap(arr, pos + dist, pos + right)
            dist += 1
            right += 1
    if left < left_end:
        length = left_end - left
        while left < left_end:
            left_end -= 1
            right_end -= 1
            swap(arr, pos + left_end, pos + right_end)
    else:
        length = right_end - right
    return length


def merge_buffers_left(arr, pos, block_count, block_len, a_block_count, last_len):
    if block_count == 0:
        merge_left(arr, pos, a_block_count * block_len, last_len, -block_len)
        return
    left_over_len = block_len
    process_index = block_len
    for key_index in range(1, block_count):
        rest_to_process = process_index - left_over_len
        left_over_len = smart_merge_with_buffer(arr, pos + rest_to_process, left_over_len, block_len)
        process_index += block_len
    rest_to_process = process_index - left_over_len
    if last_len != 0:
        left_over_len += block_len * a_block_count
        merge_left(arr, pos + rest_to_process, left_over_len, last_len, -block_len)
    else:
        multi_swap(arr, pos + rest_to_process, pos + rest_to_process - block_len, left_over_len)


def build_blocks(arr, pos, length, build_len):
    dist = 1
    while dist < length:
        extra_dist = 1 if arr[pos + dist - 1] > arr[pos + dist] else 0
        swap(arr, pos + dist - 3, pos + dist - 1 + extra_dist)
        swap(arr, pos + dist - 2, pos + dist - extra_dist)
        dist += 2
    if length % 2 == 1:
        swap(arr, pos + length - 1, pos + length - 3)
    pos -= 2
    part = 2
    while part < build_len:
        left = 0
        right = length - 2 * part
        while left <= right:
            merge_left(arr, pos + left, part, part, -part)
            left += 2 * part
        rest = length - left
        if rest > part:
            merge_left(arr, pos + left, part, rest - part, -part)
        else:
            rotate(arr, pos + left - part, part, rest)
        pos -= part
        part *= 2
    rest_to_build = length % (2 * build_len)
    left_over_pos = length - rest_to_build
    if rest_to_build <= build_len:
        rotate(arr, pos + left_over_pos, rest_to_build, build_len)
    else:
        merge_right(arr, pos + left_over_pos, build_len, rest_to_build - build_len, build_len)
    while left_over_pos > 0:
        left_over_pos -= 2 * build_len
        merge_right(arr, pos + left_over_pos, build_len, build_len, build_len)


def combine_blocks(arr, pos, length, build_len, reg_block_len):
    combine_len = length // (2 * build_len)
    left_over = length % (2 * build_len)
    if left_over <= build_len:
        length -= left_over
        left_over = 0
    i = 0
    while i <= combine_len:
        if i == combine_len and left_over == 0:
            break
        block_pos = pos + i * 2 * build_len
        block_count = (left_over if i == combine_len else 2 * build_len) // reg_block_len
        for index in range(1, block_count):
            left_index = index - 1
            for right_index in range(index, block_count):
                a = arr[block_pos + left_index * reg_block_len]
                b = arr[block_pos + right_index * reg_block_len]
                cmp = (a > b) - (a < b)
                if cmp > 0 or (cmp == 0 and arr[block_pos + (left_index + 1) * reg_block_len - 1] >
                               arr[block_pos + (right_index + 1) * reg_block_len - 1]):
                    left_index = right_index
            if left_index != index - 1:
                multi_swap(arr, block_pos + (index - 1) * reg_block_len, block_pos + left_index * reg_block_len, reg_block_len)
        a_block_count = 0
        last_len = (left_over % reg_block_len) if i == combine_len else 0
        if last_len != 0:
            while a_block_count < block_count and arr[block_pos + block_count * reg_block_len] < arr[
                    block_pos + (block_count - a_block_count - 1) * reg_block_len]:
                a_block_count += 1
        merge_buffers_left(arr, block_pos, block_count - a_block_count, reg_block_len, a_block_count, last_len)
        i += 1
    while length > 0:
        length -= 1
        swap(arr, pos + length, pos + length - reg_block_len)


def common_sort(arr, pos, length):
    if length <= 16:
        insert_sort(arr, pos, length)
        return
    block_len = 1
    while block_len * block_len < length:
        block_len *= 2
    build_len = block_len
    build_blocks(arr, pos + block_len, length - block_len, build_len)
    while True:
        build_len *= 2
        if length - block_len <= build_len:
            break
        combine_blocks(arr, pos + block_len, length - block_len, build_len, block_len)
    insert_sort(arr, pos, block_len)
    merge_without_buffer(arr, pos, block_len, length - block_len)


def sort(arr):
    n = len(arr)
    common_sort(arr, 0, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
