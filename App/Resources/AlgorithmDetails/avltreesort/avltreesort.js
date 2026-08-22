class Node {
  constructor(value) {
    this.value = value;
    this.left = null;
    this.right = null;
    this.balance = 0;
  }
}

function singleRotateRight(node) {
  const b = node.left;
  node.left = b.right;
  b.right = node;
  node.balance = 0;
  b.balance = 0;
  return b;
}

function singleRotateLeft(node) {
  const b = node.right;
  node.right = b.left;
  b.left = node;
  node.balance = 0;
  b.balance = 0;
  return b;
}

function doubleRotateRight(node) {
  const oldBBalance = node.left.right.balance;
  node.left = singleRotateLeft(node.left);
  const b = singleRotateRight(node);
  if (oldBBalance === -1) b.right.balance = 1;
  if (oldBBalance === 1) b.left.balance = -1;
  return b;
}

function doubleRotateLeft(node) {
  const oldBBalance = node.right.left.balance;
  node.right = singleRotateRight(node.right);
  const b = singleRotateLeft(node);
  if (oldBBalance === -1) b.right.balance = 1;
  if (oldBBalance === 1) b.left.balance = -1;
  return b;
}

function heightChangeLeft(node) {
  if (node.balance !== -1) {
    node.balance -= 1;
    return { node: node, heightChanged: node.balance === -1 };
  }
  if (node.left.balance === -1) {
    return { node: singleRotateRight(node), heightChanged: false };
  }
  return { node: doubleRotateRight(node), heightChanged: false };
}

function heightChangeRight(node) {
  if (node.balance !== 1) {
    node.balance += 1;
    return { node: node, heightChanged: node.balance === 1 };
  }
  if (node.right.balance === 1) {
    return { node: singleRotateLeft(node), heightChanged: false };
  }
  return { node: doubleRotateLeft(node), heightChanged: false };
}

function add(node, value) {
  if (node === null) {
    return { node: new Node(value), heightChanged: true };
  }
  if (value < node.value) {
    const result = add(node.left, value);
    node.left = result.node;
    if (result.heightChanged) {
      return heightChangeLeft(node);
    }
    return { node: node, heightChanged: false };
  } else {
    const result = add(node.right, value);
    node.right = result.node;
    if (result.heightChanged) {
      return heightChangeRight(node);
    }
    return { node: node, heightChanged: false };
  }
}

function sort(arr) {
  let root = null;
  for (const value of arr) {
    root = add(root, value).node;
  }

  const result = [];

  function traverse(node) {
    if (node === null) {
      return;
    }
    traverse(node.left);
    result.push(node.value);
    traverse(node.right);
  }

  traverse(root);

  for (let i = 0; i < arr.length; i++) {
    arr[i] = result[i];
  }
  return arr;
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
