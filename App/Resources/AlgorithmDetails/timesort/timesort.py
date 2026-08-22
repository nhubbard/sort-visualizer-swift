def sort(arr):
    n = len(arr)
    if n <= 1:
        return

    # Simulate the reporting order that proportional-to-value sleep durations
    # would produce in a jitter-free race: sort by value, ties broken by the
    # original position, i.e. the order the sleeps were originally scheduled.
    woken = sorted((value, index) for index, value in enumerate(arr))
    for i in range(n):
        arr[i] = woken[i][0]

    # Defensive cleanup pass: real scheduling jitter can't be fully trusted,
    # so finish with an ordinary insertion sort no matter what the race produced.
    for i in range(1, n):
        j = i
        while j > 0 and arr[j - 1] > arr[j]:
            arr[j - 1], arr[j] = arr[j], arr[j - 1]
            j -= 1


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
