def find_min_max(array, a, b):
    min_value = array[a]
    max_value = min_value
    for i in range(a + 1, b):
        if array[i] < min_value:
            min_value = array[i]
        elif array[i] > max_value:
            max_value = array[i]
    return min_value, max_value

def insertion_sort_range(array, s, e):
    for i in range(s + 1, e):
        j = i
        while j > s and array[j - 1] > array[j]:
            array[j - 1], array[j] = array[j], array[j - 1]
            j -= 1

def sift_down(array, s, root, size):
    while True:
        largest = root
        left = 2 * root + 1
        right = 2 * root + 2
        if left < size and array[s + largest] < array[s + left]:
            largest = left
        if right < size and array[s + largest] < array[s + right]:
            largest = right
        if largest == root:
            break
        array[s + root], array[s + largest] = array[s + largest], array[s + root]
        root = largest

def heap_sort_range(array, s, e):
    size = e - s
    if size <= 1:
        return
    i = size // 2 - 1
    while i >= 0:
        sift_down(array, s, i, size)
        i -= 1
    end = size - 1
    while end > 0:
        array[s], array[s + end] = array[s + end], array[s]
        sift_down(array, s, 0, end)
        end -= 1

def static_sort(array, a, b):
    min_value, max_value = find_min_max(array, a, b)
    aux_len = b - a
    count = [0] * (aux_len + 1)
    offset = [0] * (aux_len + 1)
    const = aux_len / (max_value - min_value + 1)

    def classify(value):
        return int((value - min_value) * const)

    for i in range(a, b):
        idx = classify(array[i])
        count[idx] += 1

    offset[0] = a
    for i in range(1, aux_len):
        offset[i] = count[i - 1] + offset[i - 1]

    for v in range(aux_len):
        while count[v] > 0:
            origin = offset[v]
            frm = origin
            num = array[frm]
            array[frm] = -1
            while True:
                idx = classify(num)
                to = offset[idx]
                offset[idx] += 1
                count[idx] -= 1
                temp = array[to]
                array[to] = num
                num = temp
                frm = to
                if frm == origin:
                    break

    for i in range(aux_len):
        s = offset[i - 1] if i > 1 else a
        e = offset[i]
        if e - s <= 1:
            continue
        if e - s > 16:
            heap_sort_range(array, s, e)
        else:
            insertion_sort_range(array, s, e)

def sort(arr):
    if len(arr) > 1:
        static_sort(arr, 0, len(arr))

if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23,
        90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
