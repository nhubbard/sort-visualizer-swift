def hyperfloor(n):
    power = 1
    while power * 2 <= n:
        power *= 2
    return power


def unchecked_insertion_sort(array, first, last):
    cur = first + 1
    while cur != last:
        if array[cur] < array[cur - 1]:
            tmp = array[cur]
            sift = cur
            sift1 = cur - 1
            while True:
                array[sift] = array[sift1]
                sift -= 1
                if sift == first:
                    break
                sift1 -= 1
                if tmp >= array[sift1]:
                    break
            array[sift] = tmp
        cur += 1


def insertion_sort(array, first, last):
    if first == last:
        return
    unchecked_insertion_sort(array, first, last)


def poplar_sift(array, first_in, size_in):
    size = size_in
    if size < 2:
        return
    root = first_in + (size - 1)
    child_root1 = root - 1
    child_root2 = first_in + (size // 2 - 1)
    while True:
        max_root = root
        if array[max_root] < array[child_root1]:
            max_root = child_root1
        if array[max_root] < array[child_root2]:
            max_root = child_root2
        if max_root == root:
            return
        array[root], array[max_root] = array[max_root], array[root]
        size //= 2
        if size < 2:
            return
        root = max_root
        child_root1 = root - 1
        child_root2 = max_root - (size - size // 2)


def pop_heap_with_size(array, first, last, size_in):
    size = size_in
    poplar_size = hyperfloor(size + 1) - 1
    last_root = last - 1
    bigger = last_root
    bigger_size = poplar_size

    it = first
    while True:
        root = it + poplar_size - 1
        if root == last_root:
            break
        if array[bigger] < array[root]:
            bigger = root
            bigger_size = poplar_size
        it = root + 1
        size -= poplar_size
        poplar_size = hyperfloor(size + 1) - 1

    if bigger != last_root:
        array[bigger], array[last_root] = array[last_root], array[bigger]
        poplar_sift(array, bigger - (bigger_size - 1), bigger_size)


def make_heap(array, first, last):
    size = last - first
    if size < 2:
        return
    small_poplar_size = 15
    if size <= small_poplar_size:
        unchecked_insertion_sort(array, first, last)
        return

    poplar_level = 1
    it = first
    next_ = it + small_poplar_size
    while True:
        unchecked_insertion_sort(array, it, next_)
        poplar_size = small_poplar_size
        i = (poplar_level & -poplar_level) >> 1
        while i != 0:
            it -= poplar_size
            poplar_size = 2 * poplar_size + 1
            if it + poplar_size > last:
                break
            poplar_sift(array, it, poplar_size)
            next_ += 1
            i >>= 1
        if (last - next_) <= small_poplar_size:
            insertion_sort(array, next_, last)
            return
        it = next_
        next_ += small_poplar_size
        poplar_level += 1


def sort_heap(array, first, last_in):
    last = last_in
    size = last - first
    if size < 2:
        return
    while True:
        pop_heap_with_size(array, first, last, size)
        last -= 1
        size -= 1
        if size <= 1:
            break


def sort(array):
    n = len(array)
    if n <= 1:
        return
    make_heap(array, 0, n)
    sort_heap(array, 0, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
