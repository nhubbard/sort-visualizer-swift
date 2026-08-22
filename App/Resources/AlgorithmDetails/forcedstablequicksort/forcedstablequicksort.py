def stable_comp(arr, key, a, b):
    if arr[a] > arr[b]:
        return True
    if arr[a] == arr[b]:
        return key[a] > key[b]
    return False


def stable_swap(arr, key, a, b):
    arr[a], arr[b] = arr[b], arr[a]
    key[a], key[b] = key[b], key[a]


def median_of_three(arr, key, a, b):
    m = a + (b - 1 - a) // 2
    if stable_comp(arr, key, a, m):
        stable_swap(arr, key, a, m)
    if stable_comp(arr, key, m, b - 1):
        stable_swap(arr, key, m, b - 1)
        if stable_comp(arr, key, a, m):
            return
    stable_swap(arr, key, a, m)


def partition(arr, key, a, b, p):
    i = a - 1
    j = b
    while True:
        while True:
            i += 1
            if not (i < j and not stable_comp(arr, key, i, p)):
                break
        while True:
            j -= 1
            if not (j >= i and stable_comp(arr, key, j, p)):
                break
        if i < j:
            stable_swap(arr, key, i, j)
        else:
            return j


def quick_sort(arr, key, a, b):
    if b - a < 3:
        if b - a == 2 and stable_comp(arr, key, a, a + 1):
            stable_swap(arr, key, a, a + 1)
        return
    median_of_three(arr, key, a, b)
    p = partition(arr, key, a + 1, b, a)
    stable_swap(arr, key, a, p)
    quick_sort(arr, key, a, p)
    quick_sort(arr, key, p + 1, b)


def sort(arr):
    n = len(arr)
    key = list(range(n))
    quick_sort(arr, key, 0, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
