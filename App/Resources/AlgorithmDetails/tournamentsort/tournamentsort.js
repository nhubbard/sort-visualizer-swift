function sort(array) {
  const n = array.length;
  if (n <= 1) return array;

  // matches[root], matches[root + 1], matches[root + 2] hold (winner, winners, losers) for
  // a match node at slot `root`. `winners`/`losers` are references: either a player leaf,
  // encoded as `-playerIndex` (so `<= 0`), or another match node's root offset (`> 0`).
  const matches = new Array(6 * n).fill(0);

  const isPlayer = (ref) => ref <= 0;
  const makePlayer = (index) => -index;
  const getWinner = (root) => matches[root];
  const getWinners = (root) => matches[root + 1];
  const getLosers = (root) => matches[root + 2];
  const setMatch = (root, winner, winners, losers) => {
    matches[root] = winner;
    matches[root + 1] = winners;
    matches[root + 2] = losers;
  };
  const getPlayer = (ref) => (isPlayer(ref) ? Math.abs(ref) : getWinner(ref));

  const makeMatch = (top, bot, root) => {
    const topWinner = getPlayer(top);
    const botWinner = getPlayer(bot);
    if (array[topWinner] <= array[botWinner]) {
      setMatch(root, topWinner, top, bot);
    } else {
      setMatch(root, botWinner, bot, top);
    }
    return root;
  };

  const knockout = (i, k, root) => {
    if (i === k) return makePlayer(i);
    const mid = Math.floor((i + k) / 2);
    const leftRef = knockout(i, mid, 2 * root);
    const rightRef = knockout(mid + 1, k, 2 * root + 3);
    return makeMatch(leftRef, rightRef, root);
  };

  const rebuild = (root) => {
    if (isPlayer(getWinners(root))) {
      return getLosers(root);
    }
    matches[root + 1] = rebuild(getWinners(root));
    if (
      array[getPlayer(getLosers(root))] < array[getPlayer(getWinners(root))]
    ) {
      matches[root] = getPlayer(getLosers(root));
      const previousLosers = getLosers(root);
      matches[root + 2] = getWinners(root);
      matches[root + 1] = previousLosers;
    } else {
      matches[root] = getPlayer(getWinners(root));
    }
    return root;
  };

  let tourney = knockout(0, n - 1, 3);

  const pop = () => {
    const result = array[getPlayer(tourney)];
    tourney = isPlayer(tourney) ? 0 : rebuild(tourney);
    return result;
  };

  const output = new Array(n);
  for (let i = 0; i < n; i++) {
    output[i] = pop();
  }
  return output;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
array = sort(array);
console.log("[" + array.join(", ") + "]");
