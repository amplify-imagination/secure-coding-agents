const net = require("net");
const [LPORT, RHOST, RPORT] = [1234, "host.containers.internal", 1234];
net.createServer(c => {
  const u = net.connect(RPORT, RHOST);
  c.pipe(u); u.pipe(c);
  u.on("error", () => c.destroy()); c.on("error", () => u.destroy());
}).listen(LPORT, () => console.log("model relay up on :"+LPORT));
