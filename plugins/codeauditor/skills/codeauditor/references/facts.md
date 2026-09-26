# Dated facts

Last reviewed: 2026-09-26. These change with releases. When the project pins a version newer than this review, check that version's release notes before you rely on a line here, and say so in Scope and limitations. Cards that use this file: ERR-R1, ERR-R3, DEP-R2, DEP-R3.

## Default timeouts of common HTTP clients (ERR-R3)

| Client | Default when no timeout is passed |
|---|---|
| Python `requests` | none: waits forever; a `Session` has no default either |
| Python `urllib.request.urlopen` | the global socket default, which is none unless `socket.setdefaulttimeout` was called |
| Python `httpx` | 5 seconds |
| Python `aiohttp` | 5 minutes in total |
| Node.js `fetch` (undici) | no overall limit; 300 seconds for headers and 300 seconds between body chunks |
| Node.js `http` and `https` | none |
| `axios` | none (`timeout: 0`) |
| `node-fetch` 2.x | none; 3.x removed the `timeout` option, so pass `signal: AbortSignal.timeout(ms)` |
| Go `net/http` (`http.Get`, `http.Client{}`) | none: a zero `Client.Timeout` means no limit |
| Java `java.net.http.HttpClient` | no connect or request timeout unless set |
| .NET `HttpClient` | 100 seconds |

## Errors that vanish (ERR-R1)

- Express 4 does not pass a rejected promise from an `async` route handler to the error middleware. The request hangs, and on Node.js 15 or later the unhandled rejection ends the process unless an `unhandledRejection` handler is installed. Express 5 (stable since 2024) forwards rejected promises to the error middleware.
- Node.js 15 and later crash on an unhandled promise rejection by default (`--unhandled-rejections=throw`).
- `array.forEach(async ...)` does not wait for its callbacks: the caller carries on before the work finishes, and their rejections go unhandled.
- Python `asyncio.create_task`: the event loop keeps only a weak reference to a task, so a task whose result nobody stores can be garbage-collected before it finishes, and its exception is never seen.
- A `return` inside `finally` discards the exception in flight in JavaScript, Python, and Java.

## Runtime end of life (DEP-R2)

- Node.js: 18 reached end of life on 2025-04-30 and 20 on 2026-04-30; 22 is in maintenance until 2027-04-30; 24 is the active LTS line. Odd-numbered majors never become LTS and lose support after about six months.
- Python: 3.8 reached end of life in October 2024 and 3.9 in October 2025; 3.10 reaches it in October 2026.
- Go: each major release is supported until two newer majors exist, so only the latest two get security fixes.
- For other runtimes, check the project's official release schedule and cite it.

## Deprecated or unmaintained packages (DEP-R2)

- npm: `request` (deprecated in 2020), `moment` (maintenance only since 2020; its authors point to Luxon, date-fns, Day.js, or Temporal), `node-sass` (deprecated; use `sass`), `tslint` (deprecated in 2019 in favor of typescript-eslint), `@babel/polyfill` (deprecated since Babel 7.4).
- Python: `pycrypto` (last released in 2013, with known vulnerabilities; use `cryptography` or `pycryptodome`), `nose` (unmaintained since 2015; use pytest).
- Java: log4j 1.x (end of life since 2015; use log4j 2 or another maintained logger).

## Deprecated or removed APIs (DEP-R3)

- Node.js: `new Buffer()` is deprecated (use `Buffer.from` or `Buffer.alloc`); `url.parse()` is legacy (use the WHATWG `URL` class); `crypto.createCipher` and `crypto.createDecipher` are deprecated since Node.js 10 (use `createCipheriv` and `createDecipheriv`).
- Python 3.12 removed `distutils`, `imp`, `asyncore`, `asynchat`, and `smtpd`, and deprecated `datetime.utcnow()` and `datetime.utcfromtimestamp()` (use `datetime.now(timezone.utc)`). Python 3.13 removed the PEP 594 modules (`cgi`, `cgitb`, `crypt`, `imghdr`, `pipes`, `telnetlib`, `nntplib`, and others) and `lib2to3`. setuptools deprecates `pkg_resources` (use `importlib.metadata` and `importlib.resources`).
- React 19 removed `ReactDOM.render`, `ReactDOM.hydrate`, `unmountComponentAtNode`, `findDOMNode`, string refs, and legacy context, and ignores `propTypes` (use `createRoot`, `hydrateRoot`, and ref callbacks or `useRef`). `componentWillMount`, `componentWillReceiveProps`, and `componentWillUpdate` are deprecated since React 16.3 (renamed with an `UNSAFE_` prefix).
- Express 5 removed `app.del()`, `req.param()`, and `res.sendfile()` (use `app.delete()`, `req.params` or `req.query` or `req.body`, and `res.sendFile()`), and requires named wildcards in route paths (`/*splat`).
- Go: `io/ioutil` is deprecated since Go 1.16 (use the `io` and `os` functions).
- Java: `Object.finalize()` is deprecated for removal since JDK 18, and the `SecurityManager` is permanently disabled since JDK 24.
