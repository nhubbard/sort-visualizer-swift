def stable_comp(arr, table, a, b):
    ta = table[a]
    tb = table[b]
    if arr[ta] > arr[tb]:
        return True
    if arr[ta] == arr[tb]:
        return table[a] > table[b]
    return False


def median_of_three(arr, table, a, b):
    m = a + (b - 1 - a) // 2
    if stable_comp(arr, table, a, m):
        table[a], table[m] = table[m], table[a]
    if stable_comp(arr, table, m, b - 1):
        table[m], table[b - 1] = table[b - 1], table[m]
        if stable_comp(arr, table, a, m):
            return
    table[a], table[m] = table[m], table[a]


def partition(arr, table, a, b, p):
    i = a - 1
    j = b
    while True:
        while True:
            i += 1
            if not (i < j and not stable_comp(arr, table, i, p)):
                break
        while True:
            j -= 1
            if not (j >= i and stable_comp(arr, table, j, p)):
                break
        if i < j:
            table[i], table[j] = table[j], table[i]
        else:
            return j


def quick_sort(arr, table, a, b):
    if b - a < 3:
        if b - a == 2 and stable_comp(arr, table, a, a + 1):
            table[a], table[a + 1] = table[a + 1], table[a]
        return
    median_of_three(arr, table, a, b)
    p = partition(arr, table, a + 1, b, a)
    table[a], table[p] = table[p], table[a]
    quick_sort(arr, table, a, p)
    quick_sort(arr, table, p + 1, b)


def sort(arr):
    n = len(arr)
    table = list(range(n))
    quick_sort(arr, table, 0, n)
    for i in range(n):
        if table[i] != i:
            t = arr[i]
            j = i
            next_ = table[i]
            while True:
                arr[j] = arr[next_]
                table[j] = j
                j = next_
                next_ = table[next_]
                if next_ == i:
                    break
            arr[j] = t
            table[j] = j


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
