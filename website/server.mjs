import http from 'node:http';
import {createReadStream, statSync} from 'node:fs';
import {resolve, dirname, extname, sep} from 'node:path';
import {Transform} from 'node:stream';
import {fileURLToPath} from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const publicRoot = resolve(here, 'public');
const appRoot = resolve(here, '.build/app');
const upstream = new URL(process.env.CONNECT_API_UPSTREAM || 'http://127.0.0.1:18080');
const port = Number(process.env.PORT || 4190);
const host = process.env.HOST || '127.0.0.1';
const maxProxyBodyBytes = Number(process.env.WEB_MAX_PROXY_BODY_BYTES || 25 * 1024 * 1024);
const allowedHosts = new Set(
  (process.env.WEB_ALLOWED_HOSTS || `127.0.0.1:${port},localhost:${port},[::1]:${port}`)
    .split(',').map(value => value.trim().toLowerCase()).filter(Boolean),
);
const mime = {'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.json':'application/json','.png':'image/png','.svg':'image/svg+xml','.ttf':'font/ttf','.woff2':'font/woff2','.wasm':'application/wasm','.ico':'image/x-icon','.bin':'application/octet-stream'};
function isAllowedHost(req) {
  return allowedHosts.has(String(req.headers.host || '').trim().toLowerCase());
}
function applySecurityHeaders(res, appPath = false) {
  const contentPolicy = appPath
    ? "default-src 'self'; base-uri 'self'; connect-src 'self' blob: https://fonts.gstatic.com ws: wss:; font-src 'self' data: https://fonts.gstatic.com; form-action 'self'; frame-ancestors 'none'; img-src 'self' data: blob:; media-src 'self' blob:; object-src 'none'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; worker-src 'self' blob:"
    : "default-src 'self'; base-uri 'self'; connect-src 'self'; font-src 'self'; form-action 'self'; frame-ancestors 'none'; img-src 'self'; media-src 'self'; object-src 'none'; script-src 'self'; style-src 'self'";
  res.setHeader('Content-Security-Policy', contentPolicy);
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin-allow-popups');
  res.setHeader('Cross-Origin-Resource-Policy', 'same-origin');
  res.setHeader('Permissions-Policy', 'camera=(self), microphone=(self), geolocation=(), usb=()');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
}
function proxyHeaders(req) {
  // Preserve the browser host: the gateway derives its trusted forwarded host
  // from Host for WebSocket origin checks and media URLs.
  const headers = {...req.headers, host: req.headers.host};
  delete headers['x-forwarded-host']; delete headers['x-forwarded-proto']; delete headers['x-forwarded-for'];
  headers['x-forwarded-host'] = req.headers.host;
  headers['x-forwarded-proto'] = 'http';
  return headers;
}
const server = http.createServer((req,res) => {
  let requestURL, path;
  try { requestURL = new URL(req.url, 'http://localhost'); path = decodeURIComponent(requestURL.pathname); }
  catch { res.writeHead(400); res.end('Invalid URL'); return; }
  applySecurityHeaders(res, path === '/app' || path.startsWith('/app/') || path.startsWith('/v1/'));
  if (!isAllowedHost(req)) { res.writeHead(421, {'Content-Type':'text/plain; charset=utf-8', 'Cache-Control':'no-store'}); res.end('Misdirected request'); return; }
  if (path.startsWith('/v1/')) {
    const contentLength = Number(req.headers['content-length'] || 0);
    if (!Number.isFinite(contentLength) || contentLength < 0 || contentLength > maxProxyBodyBytes) {
      res.writeHead(413, {'Content-Type':'application/json', 'Cache-Control':'no-store'});
      res.end(JSON.stringify({error:'Request body is too large.'})); return;
    }
    const upstreamPath = `${requestURL.pathname}${requestURL.search}`;
    let bodyRejected = false;
    const proxy = http.request(upstream, {method:req.method, path:upstreamPath, headers:proxyHeaders(req)}, response => {
      res.writeHead(response.statusCode, {...response.headers, 'Cache-Control':'no-store'}); response.pipe(res);
    });
    proxy.setTimeout(35000, () => proxy.destroy(new Error('API timeout')));
    proxy.on('error', () => { if (bodyRejected) return; if (!res.headersSent) res.writeHead(502, {'Content-Type':'application/json'}); res.end(JSON.stringify({error:'The service is temporarily unavailable. Please try again.'})); });
    let received = 0;
    const limiter = new Transform({
      transform(chunk, _encoding, callback) {
        received += chunk.length;
        if (received > maxProxyBodyBytes) return callback(new Error('request body limit exceeded'));
        callback(null, chunk);
      },
    });
    limiter.on('error', () => {
      bodyRejected = true;
      proxy.destroy();
      if (!res.headersSent) res.writeHead(413, {'Content-Type':'application/json', 'Cache-Control':'no-store'});
      if (!res.writableEnded) res.end(JSON.stringify({error:'Request body is too large.'}));
    });
    req.pipe(limiter).pipe(proxy); return;
  }
  if (!['GET','HEAD'].includes(req.method)) { res.writeHead(405); res.end(); return; }
  if (path === '/app') { res.writeHead(302, {Location:'/app/'}); res.end(); return; }
  if (path === '/healthz') { res.writeHead(200, {'Content-Type':'application/json'}); res.end('{"status":"ok","service":"connect-website"}'); return; }
  const root = path.startsWith('/app/') ? appRoot : publicRoot;
  let relative = root === appRoot ? path.slice(5) : path.slice(1);
  if (!relative) relative = 'index.html';
  // Localised pages live under /<lang>/; a bare /<lang>/ is that locale's home.
  if (root === publicRoot && relative.endsWith('/')) relative += 'index.html';
  if (root === publicRoot && !extname(relative)) relative += '.html';
  const file = resolve(root, relative);
  if (!file.startsWith(root + sep) || relative.split('/').some(p=>p.startsWith('.'))) { res.writeHead(403); res.end('Forbidden'); return; }
  try {
    if (!statSync(file).isFile()) throw new Error('not file');
    res.writeHead(200, {
      'Content-Type':mime[extname(file)] || 'application/octet-stream',
      'Cache-Control':extname(file)==='.html' || file.endsWith('flutter_bootstrap.js') ? 'no-store' : 'no-cache',
    });
    if(req.method==='HEAD') res.end(); else createReadStream(file).pipe(res);
  } catch {
    res.writeHead(404, {'Content-Type':'text/html; charset=utf-8'});
    res.end('<!doctype html><html lang="en"><title>Page not found · Connect</title><body><h1>This page wandered off.</h1><p><a href="/">Back to Connect</a></p></body></html>');
  }
});
server.on('upgrade',(req,socket,head)=>{
  if (!isAllowedHost(req)) {socket.destroy();return;}
  const parsed=new URL(req.url,'http://localhost');
  const path=parsed.pathname;
  if(!['/v1/realtime/chat','/v1/realtime/notifications'].includes(path)) {socket.destroy();return;}
  const proxy=http.request(upstream,{method:'GET',path:`${parsed.pathname}${parsed.search}`,headers:proxyHeaders(req)});
  proxy.on('upgrade',(response,remote,remoteHead)=>{
    socket.write(`HTTP/1.1 101 Switching Protocols\r\n${Object.entries(response.headers).map(([k,v])=>`${k}: ${v}`).join('\r\n')}\r\n\r\n`);
    if(remoteHead.length) socket.write(remoteHead);
    if(head.length) remote.write(head);
    remote.pipe(socket); socket.pipe(remote);
    remote.on('error',()=>socket.destroy()); socket.on('error',()=>remote.destroy());
    socket.on('close',()=>remote.destroy()); remote.on('close',()=>socket.destroy());
  });
  proxy.on('response',response=>{ socket.end(`HTTP/1.1 ${response.statusCode} Unauthorized\r\nConnection: close\r\n\r\n`); response.resume(); });
  proxy.on('error',()=>socket.destroy());proxy.end();
});
server.requestTimeout = 40_000;
server.headersTimeout = 10_000;
server.keepAliveTimeout = 5_000;
server.maxHeadersCount = 100;
server.listen(port,host,()=>console.log(`Connect website: http://${host}:${port}`));
