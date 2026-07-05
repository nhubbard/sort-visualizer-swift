// ArrayV-original strand extraction sort. subList is tracked in a plain JS array alongside a
// mirrored aux array (writeAux) purely so the visualization has something to render.
function sort(engine) {
    const n = engine.count();
    if (n < 2) return;

    const subListHandle = engine.createAuxArray(n);
    let subList = [];

    function writeSubList(index, value) {
        subList[index] = value;
        engine.writeAux(subListHandle, index, value);
    }

    function mergeTo(a, m, b) {
        let i = 0;
        const s = m - a;
        while (i < s && m < b) {
            if (subList[i] < engine.getValue(m)) {
                engine.setValue(a, subList[i]);
                a++; i++;
            } else {
                engine.setValue(a, engine.getValue(m));
                a++; m++;
            }
        }
        while (i < s) {
            engine.setValue(a, subList[i]);
            a++; i++;
        }
    }

    let j = n;
    let k = j;
    while (j > 0) {
        writeSubList(0, engine.getValue(0));
        k--;

        let i = 0;
        let p = 0;
        for (let m = 1; m < j; m++) {
            if (engine.getValue(m) >= subList[i]) {
                i++;
                writeSubList(i, engine.getValue(m));
                k--;
            } else {
                engine.setValue(p, engine.getValue(m));
                p++;
            }
        }

        mergeTo(k, j, n);
        j = k;
    }

    engine.deleteAuxArray(subListHandle);
}
