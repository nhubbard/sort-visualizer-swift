# [start, stop) is the half-open range being sorted. merge selects whether
# the two halves are recursively pre-sorted before the fixed diamond
# comparison pattern below merges them together.
def sort(array, start, stop, merge):
    if stop - start == 2:
        if stop <= len(array) and array[start] > array[stop - 1]:
            array[start], array[stop - 1] = array[stop - 1], array[start]
    elif stop - start >= 3:
        div = (stop - start) / 4.0
        mid = (stop - start) // 2 + start
        quarter = int(div) + start
        three_quarters = int(div * 3) + start

        if merge:
            sort(array, start, mid, True)
            sort(array, mid, stop, True)
        sort(array, quarter, three_quarters, False)
        sort(array, start, mid, False)
        sort(array, mid, stop, False)
        sort(array, quarter, three_quarters, False)


def sort_array(array):
    if len(array) < 2:
        return
    padded_length = 1
    while padded_length < len(array):
        padded_length *= 2
    sort(array, 0, padded_length, True)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort_array(array)
    print(array)
