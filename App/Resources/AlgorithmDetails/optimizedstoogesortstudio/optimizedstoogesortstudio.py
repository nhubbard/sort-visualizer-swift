def comp_swap(arr, a, b):
    if arr[a] > arr[b]:
        arr[a], arr[b] = arr[b], arr[a]
        return True
    return False


def stooge_sort(arr, a, m, b, merge):
    if a >= m:
        return False
    if b - a == 2:
        return comp_swap(arr, a, m)

    l_change = False
    r_change = False

    a2 = (a + a + b) // 3
    b2 = (a + b + b + 2) // 3

    if m < b2:
        l_change = stooge_sort(arr, a, m, b2, merge)
        if merge:
            r_change = stooge_sort(arr, max(a + b2 - m, a2), b2, b, True)
            if r_change:
                stooge_sort(arr, a + b2 - m, a2, 2 * a2 - a, True)
        else:
            r_change = stooge_sort(arr, a2, b2, b, False)
            if r_change:
                stooge_sort(arr, a, a2, 2 * a2 - a, True)
    else:
        r_change = stooge_sort(arr, a2, m, b, merge)
        if r_change:
            stooge_sort(arr, a, a2, a2 + b - m, True)

    return l_change or r_change


def sort(arr):
    stooge_sort(arr, 0, 1, len(arr), False)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
