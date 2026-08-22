def sort(array):
    n = len(array)
    if n <= 1:
        return array

    # matches[root], matches[root + 1], matches[root + 2] hold (winner, winners, losers) for
    # a match node at slot `root`. `winners`/`losers` are references: either a player leaf,
    # encoded as `-player_index` (so `<= 0`), or another match node's root offset (`> 0`).
    matches = [0] * (6 * n)

    def is_player(ref):
        return ref <= 0

    def make_player(index):
        return -index

    def get_winner(root):
        return matches[root]

    def get_winners(root):
        return matches[root + 1]

    def get_losers(root):
        return matches[root + 2]

    def set_match(root, winner, winners, losers):
        matches[root] = winner
        matches[root + 1] = winners
        matches[root + 2] = losers

    def get_player(ref):
        return abs(ref) if is_player(ref) else get_winner(ref)

    def make_match(top, bot, root):
        top_winner = get_player(top)
        bot_winner = get_player(bot)
        if array[top_winner] <= array[bot_winner]:
            set_match(root, top_winner, top, bot)
        else:
            set_match(root, bot_winner, bot, top)
        return root

    def knockout(i, k, root):
        if i == k:
            return make_player(i)
        mid = (i + k) // 2
        left_ref = knockout(i, mid, 2 * root)
        right_ref = knockout(mid + 1, k, 2 * root + 3)
        return make_match(left_ref, right_ref, root)

    def rebuild(root):
        if is_player(get_winners(root)):
            return get_losers(root)
        matches[root + 1] = rebuild(get_winners(root))
        if array[get_player(get_losers(root))] < array[get_player(get_winners(root))]:
            matches[root] = get_player(get_losers(root))
            previous_losers = get_losers(root)
            matches[root + 2] = get_winners(root)
            matches[root + 1] = previous_losers
        else:
            matches[root] = get_player(get_winners(root))
        return root

    tourney = knockout(0, n - 1, 3)

    def pop():
        nonlocal tourney
        result = array[get_player(tourney)]
        tourney = 0 if is_player(tourney) else rebuild(tourney)
        return result

    return [pop() for _ in range(n)]


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    array = sort(array)
    print(array)
