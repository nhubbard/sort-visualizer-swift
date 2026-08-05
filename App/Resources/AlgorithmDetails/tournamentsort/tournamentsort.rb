def sort(array)
  n = array.length
  return array if n <= 1

  # matches[root], matches[root + 1], matches[root + 2] hold (winner, winners, losers) for
  # a match node at slot `root`. `winners`/`losers` are references: either a player leaf,
  # encoded as `-player_index` (so `<= 0`), or another match node's root offset (`> 0`).
  matches = Array.new(6 * n, 0)

  is_player = ->(ref) { ref <= 0 }
  make_player = ->(index) { -index }
  get_winner = ->(root) { matches[root] }
  get_winners = ->(root) { matches[root + 1] }
  get_losers = ->(root) { matches[root + 2] }
  set_match = lambda do |root, winner, winners, losers|
    matches[root] = winner
    matches[root + 1] = winners
    matches[root + 2] = losers
  end
  get_player = ->(ref) { is_player.call(ref) ? ref.abs : get_winner.call(ref) }

  make_match = lambda do |top, bot, root|
    top_winner = get_player.call(top)
    bot_winner = get_player.call(bot)
    if array[top_winner] <= array[bot_winner]
      set_match.call(root, top_winner, top, bot)
    else
      set_match.call(root, bot_winner, bot, top)
    end
    root
  end

  knockout = lambda do |i, k, root|
    next make_player.call(i) if i == k
    mid = (i + k) / 2
    left_ref = knockout.call(i, mid, 2 * root)
    right_ref = knockout.call(mid + 1, k, 2 * root + 3)
    make_match.call(left_ref, right_ref, root)
  end

  rebuild = lambda do |root|
    next get_losers.call(root) if is_player.call(get_winners.call(root))
    matches[root + 1] = rebuild.call(get_winners.call(root))
    if array[get_player.call(get_losers.call(root))] < array[get_player.call(get_winners.call(root))]
      matches[root] = get_player.call(get_losers.call(root))
      previous_losers = get_losers.call(root)
      matches[root + 2] = get_winners.call(root)
      matches[root + 1] = previous_losers
    else
      matches[root] = get_player.call(get_winners.call(root))
    end
    root
  end

  tourney = knockout.call(0, n - 1, 3)

  pop = lambda do
    result = array[get_player.call(tourney)]
    tourney = is_player.call(tourney) ? 0 : rebuild.call(tourney)
    result
  end

  Array.new(n) { pop.call }
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
array = sort(array)
p array
