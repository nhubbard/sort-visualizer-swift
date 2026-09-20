def sort(arr):
    if len(arr) > 1:
        dual_pivot_quick_sort(arr, 0, len(arr) - 1, 3)

def insertion_sort(array, left, right):
    for i in range(left + 1, right + 1):
        j = i
        while j > left and array[j] < array[j - 1]:
            array[j], array[j - 1] = array[j - 1], array[j]
            j -= 1


def dual_pivot_quick_sort(array, left, right, divisor):
    length = right - left
    if length < 4:
        insertion_sort(array, left, right)
        return

    third = length // divisor
    med1 = max(left + third, left + 1)
    med2 = min(right - third, right - 1)
    if array[med1] < array[med2]:
        array[med1], array[left] = array[left], array[med1]
        array[med2], array[right] = array[right], array[med2]
    else:
        array[med1], array[right] = array[right], array[med1]
        array[med2], array[left] = array[left], array[med2]

    pivot1, pivot2 = array[left], array[right]
    less, great = left + 1, right - 1
    k = less
    while k <= great:
        if array[k] < pivot1:
            array[k], array[less] = array[less], array[k]
            less += 1
        elif array[k] > pivot2:
            while k < great and array[great] > pivot2:
                great -= 1
            array[k], array[great] = array[great], array[k]
            great -= 1
            if array[k] < pivot1:
                array[k], array[less] = array[less], array[k]
                less += 1
        k += 1

    if great - less < 13:
        divisor += 1
    array[less - 1], array[left] = array[left], array[less - 1]
    array[great + 1], array[right] = array[right], array[great + 1]
    dual_pivot_quick_sort(array, left, less - 2, divisor)
    if pivot1 < pivot2:
        dual_pivot_quick_sort(array, less, great, divisor)
    dual_pivot_quick_sort(array, great + 2, right, divisor)




if __name__ == "__main__":
    array = [
        0, 39, 21, 62, 91, 77, 14, 23,
        90, 69, 51, 81, 68, 83, 32, 56,
    ]
    sort(array)
    print(array)
