function shuffle(engine) {
    // Ported from Legacy/Shared/Data/Primary/ShuffleMethod.swift's genShuffledN(power: 3, ...):
    // remap each position through a cubic curve to get a skewed value distribution, then
    // Fisher-Yates shuffle the result.
    const n = engine.count();
    for (let i = 0; i < n; i++) {
        const x = (2.0 * i / n) - 1.0;
        const v = Math.pow(x, 3);
        const w = (v + 1.0) / 2.0 * n + 1.0;
        engine.setValue(i, Math.floor(w) + 1);
    }
    for (let i = n - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        engine.swap(i, j);
    }
}
