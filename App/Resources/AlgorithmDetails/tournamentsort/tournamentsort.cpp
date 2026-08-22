#include <cstdlib>
#include <iostream>
#include <vector>

/* A `ref` is either a player leaf, encoded as `-playerIndex` (so `ref <= 0`),
 * or another match node's root offset into `matches` (so `ref > 0`). */
bool isPlayer(int ref) { return ref <= 0; }
int makePlayer(int index) { return -index; }

int getWinner(const std::vector<int> &matches, int root) {
  return matches[root];
}
int getWinners(const std::vector<int> &matches, int root) {
  return matches[root + 1];
}
int getLosers(const std::vector<int> &matches, int root) {
  return matches[root + 2];
}

void setMatch(std::vector<int> &matches, int root, int winner, int winners,
              int losers) {
  matches[root] = winner;
  matches[root + 1] = winners;
  matches[root + 2] = losers;
}

int getPlayer(const std::vector<int> &array, const std::vector<int> &matches,
              int ref) {
  return isPlayer(ref) ? std::abs(ref) : getWinner(matches, ref);
}

int makeMatch(std::vector<int> &array, std::vector<int> &matches, int top,
              int bot, int root) {
  int topWinner = getPlayer(array, matches, top);
  int botWinner = getPlayer(array, matches, bot);
  if (array[topWinner] <= array[botWinner]) {
    setMatch(matches, root, topWinner, top, bot);
  } else {
    setMatch(matches, root, botWinner, bot, top);
  }
  return root;
}

int knockout(std::vector<int> &array, std::vector<int> &matches, int i, int k,
             int root) {
  if (i == k)
    return makePlayer(i);
  int mid = (i + k) / 2;
  int leftRef = knockout(array, matches, i, mid, 2 * root);
  int rightRef = knockout(array, matches, mid + 1, k, 2 * root + 3);
  return makeMatch(array, matches, leftRef, rightRef, root);
}

int rebuild(std::vector<int> &array, std::vector<int> &matches, int root) {
  if (isPlayer(getWinners(matches, root))) {
    return getLosers(matches, root);
  }
  matches[root + 1] = rebuild(array, matches, getWinners(matches, root));
  if (array[getPlayer(array, matches, getLosers(matches, root))] <
      array[getPlayer(array, matches, getWinners(matches, root))]) {
    matches[root] = getPlayer(array, matches, getLosers(matches, root));
    int previousLosers = getLosers(matches, root);
    matches[root + 2] = getWinners(matches, root);
    matches[root + 1] = previousLosers;
  } else {
    matches[root] = getPlayer(array, matches, getWinners(matches, root));
  }
  return root;
}

void sort(std::vector<int> &array) {
  int n = static_cast<int>(array.size());
  if (n <= 1)
    return;

  std::vector<int> matches(6 * n, 0);
  int tourney = knockout(array, matches, 0, n - 1, 3);

  std::vector<int> output(n);
  for (int i = 0; i < n; i++) {
    output[i] = array[getPlayer(array, matches, tourney)];
    tourney = isPlayer(tourney) ? 0 : rebuild(array, matches, tourney);
  }
  array = output;
}

int main() {
  std::vector<int> array = {0,  39, 21, 62, 91, 77, 14, 23,
                            90, 69, 51, 81, 68, 83, 32, 56};
  sort(array);
  std::cout << "[";
  for (size_t i = 0; i < array.size(); i++) {
    std::cout << array[i];
    if (i != array.size() - 1)
      std::cout << ", ";
  }
  std::cout << "]" << '\n';
  return 0;
}
