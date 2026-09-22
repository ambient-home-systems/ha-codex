// CI-only Supervisor response. No real Home Assistant instance or credentials.
const http = require('node:http');
const fs = require('node:fs');

http.createServer((request, response) => {
  response.setHeader('Content-Type', 'application/json');
  if (request.method !== 'GET' || request.url !== '/addons/self/options/config') {
    response.writeHead(404);
    response.end(JSON.stringify({ result: 'error', message: 'Unknown fixture route' }));
    return;
  }
  const options = JSON.parse(fs.readFileSync('/data/options.json', 'utf8'));
  response.end(JSON.stringify({ result: 'ok', data: options }));
}).listen(80, '0.0.0.0');
