import bisect
import heapq


def sort(arr):
    n = len(arr)
    piles = []  # list of lists (stacks); piles[i][-1] is the current top of pile i
    tops = []  # parallel list of each pile's current top value, kept sorted ascending

    for x in arr:
        # binary search: leftmost pile whose top is >= x
        i = bisect.bisect_left(tops, x)
        if i == len(piles):
            piles.append([x])
            tops.append(x)
        else:
            piles[i].append(x)
            tops[i] = x

    # min-heap of (topValue, pileIndex) pairs, to repeatedly extract the globally smallest top
    heap = [(tops[i], i) for i in range(len(piles))]
    heapq.heapify(heap)

    result = []
    while heap:
        _top_value, pile_index = heapq.heappop(heap)
        value = piles[pile_index].pop()
        result.append(value)
        if piles[pile_index]:
            heapq.heappush(heap, (piles[pile_index][-1], pile_index))

    for i in range(n):
        arr[i] = result[i]


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
