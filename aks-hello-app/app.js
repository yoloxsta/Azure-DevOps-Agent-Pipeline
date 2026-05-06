const http = require('http');
http.createServer((req, res) => {
  res.end('Hello from dev...');
}).listen(3000);