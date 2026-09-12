const net = require("net");

function createTcpConnection(host, port, tag) {
  const socket = new net.Socket();

  console.log(`[TCP:${tag}] Connecting to ${host}:${port}`);

  socket.connect(port, host, () => {
    console.log(`[TCP:${tag}] Connected to ${host}:${port}`);
  });

  return socket;
}

module.exports = { createTcpConnection };
