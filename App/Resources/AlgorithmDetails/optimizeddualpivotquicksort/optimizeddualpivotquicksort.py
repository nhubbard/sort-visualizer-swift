INSERTION_THRESHOLD = 24

# Once a range's "between the pivots" middle partition holds more than this fraction of the
# range, it's worth pausing to scan out any elements that exactly equal one of the two pivots
# before recursing into what's left.
EQUAL_ELEMENTS_MIN_FRACTION = 4


def insertion_sort(arr, low, high):
    # Sorts arr[low..high] in place (both bounds inclusive).
    for i in range(low + 1, high + 1):
        key = arr[i]
        j = i - 1
        while j >= low and arr[j] > key:
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = key


def move_pivot_duplicates_out(arr, low, high, pivot1, pivot2):
    # arr[low..high] holds only values in the closed range [pivot1, pivot2]. In a single scan,
    # moves every element equal to pivot1 to the front and every element equal to pivot2 to the
    # back -- a Dutch-national-flag-style three-way partition, generalized to two specific
    # target values instead of "less than/greater than a pivot". Returns (low, high): the
    # inclusive bounds of what's left strictly between the two pivots.
    write_low = low
    read = low
    write_high = high
    while read <= write_high:
        if arr[read] == pivot1:
            arr[read], arr[write_low] = arr[write_low], arr[read]
            write_low += 1
            read += 1
        elif arr[read] == pivot2:
            arr[read], arr[write_high] = arr[write_high], arr[read]
            write_high -= 1
        else:
            read += 1
    return write_low, write_high


def optimized_dual_pivot_quick_sort(arr, low, high):
    # Sorts arr[low..high] in place (both bounds inclusive).
    size = high - low + 1
    if size <= INSERTION_THRESHOLD:
        if size > 1:
            insertion_sort(arr, low, high)
        return

    # Sample two candidates roughly a third of the way in from each end and seed the two
    # pivots from them, smaller one first.
    third = size // 3
    pivot1_index = low + third
    pivot2_index = high - third
    if arr[pivot1_index] > arr[pivot2_index]:
        arr[pivot1_index], arr[pivot2_index] = arr[pivot2_index], arr[pivot1_index]
    arr[low], arr[pivot1_index] = arr[pivot1_index], arr[low]
    arr[high], arr[pivot2_index] = arr[pivot2_index], arr[high]
    pivot1 = arr[low]
    pivot2 = arr[high]

    # Single left-to-right scan splitting the interior into three regions: less than pivot1,
    # between the two pivots, and greater than pivot2.
    less = low + 1
    great = high - 1
    k = less
    while k <= great:
        if arr[k] < pivot1:
            arr[k], arr[less] = arr[less], arr[k]
            less += 1
        elif arr[k] > pivot2:
            while k < great and arr[great] > pivot2:
                great -= 1
            arr[k], arr[great] = arr[great], arr[k]
            great -= 1
            if arr[k] < pivot1:
                arr[k], arr[less] = arr[less], arr[k]
                less += 1
        k += 1

    # Drop the two pivots into place at the boundaries of their regions.
    less -= 1
    great += 1
    arr[low], arr[less] = arr[less], arr[low]
    arr[high], arr[great] = arr[great], arr[high]

    # arr[low..less-1] < pivot1, arr[less] == pivot1, arr[less+1..great-1] is the middle
    # region, arr[great] == pivot2, arr[great+1..high] > pivot2.
    optimized_dual_pivot_quick_sort(arr, low, less - 1)
    optimized_dual_pivot_quick_sort(arr, great + 1, high)

    middle_low = less + 1
    middle_high = great - 1

    if pivot1 != pivot2 and middle_high >= middle_low:
        middle_size = middle_high - middle_low + 1
        # Equal-elements optimization: a middle region this large is usually full of values
        # tied to one pivot or the other, which would otherwise get pointlessly re-partitioned
        # by the recursive call below. Shrink it first by scanning out the exact duplicates.
        # They're already correctly positioned relative to the low and high regions -- every
        # pivot1 duplicate is >= everything already sorted into the low region, and every
        # pivot2 duplicate is <= everything already sorted into the high region -- so neither
        # of those two regions needs to be touched again.
        if middle_size > size // EQUAL_ELEMENTS_MIN_FRACTION:
            middle_low, middle_high = move_pivot_duplicates_out(
                arr, middle_low, middle_high, pivot1, pivot2
            )

    if pivot1 != pivot2 and middle_high >= middle_low:
        optimized_dual_pivot_quick_sort(arr, middle_low, middle_high)


def sort(arr):
    n = len(arr)
    if n < 2:
        return
    optimized_dual_pivot_quick_sort(arr, 0, n - 1)


if __name__ == "__main__":
    array = [
        55,
        12,
        84,
        3,
        47,
        91,
        26,
        68,
        8,
        73,
        40,
        97,
        15,
        62,
        34,
        79,
        21,
        88,
        5,
        51,
        66,
        29,
        44,
        12,
        78,
        33,
        91,
        6,
        58,
        12,
    ]
    sort(array)
    print(array)
