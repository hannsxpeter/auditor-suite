#!/usr/bin/env node
'use strict';

/**
 * npm entry for @hxp-tools/auditor-suite.
 *
 * Materializes the packaged skills into a stable home directory
 * (~/.auditor-suite) so harness symlinks from install.sh survive npm
 * cache cleanup, then runs the existing bash installer.
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawnSync } = require('child_process');

const PKG_ROOT = path.join(__dirname, '..');
const PKG = require('../package.json');
const VERSION = PKG.version;
const HOME_INSTALL = path.join(os.homedir(), '.auditor-suite');

function usage() {
  process.stdout.write(`@hxp-tools/auditor-suite ${VERSION}

Install eight read-only audit skills into detected AI coding harnesses
(Claude Code, Codex, Cursor, Agent Skills / pi / OpenClaw).

Usage:
  npx @hxp-tools/auditor-suite@latest
  npx @hxp-tools/auditor-suite@latest --verbose
  npx @hxp-tools/auditor-suite@latest --uninstall
  npx @hxp-tools/auditor-suite@latest --version
  npx @hxp-tools/auditor-suite@latest --help

After install, run an auditor inside your agent, for example:
  /secauditor quick
  $codeauditor

Claude Code plugin alternative (pick one install method per host):
  /plugin marketplace add hannsxpeter/auditor-suite
  /plugin install auditor-suite@auditor-suite
`);
}

function copyRecursive(src, dest) {
  const st = fs.statSync(src);
  if (st.isDirectory()) {
    fs.mkdirSync(dest, { recursive: true });
    for (const name of fs.readdirSync(src)) {
      if (name === '.' || name === '..') continue;
      copyRecursive(path.join(src, name), path.join(dest, name));
    }
    return;
  }
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.copyFileSync(src, dest);
}

function materialize() {
  const skillsSrc = path.join(PKG_ROOT, 'skills');
  if (!fs.existsSync(path.join(skillsSrc, 'codeauditor', 'SKILL.md'))) {
    throw new Error('packaged skills/ missing; reinstall @hxp-tools/auditor-suite');
  }

  fs.mkdirSync(HOME_INSTALL, { recursive: true });

  const skillsDest = path.join(HOME_INSTALL, 'skills');
  fs.rmSync(skillsDest, { recursive: true, force: true });
  copyRecursive(skillsSrc, skillsDest);

  for (const name of ['install.sh', 'uninstall.sh', 'VERSION', 'LICENSE', 'README.md', 'SUITE.md']) {
    const src = path.join(PKG_ROOT, name);
    if (!fs.existsSync(src)) continue;
    fs.copyFileSync(src, path.join(HOME_INSTALL, name));
  }

  fs.writeFileSync(
    path.join(HOME_INSTALL, 'package-version.txt'),
    `${VERSION}\n`,
    'utf8'
  );

  try {
    fs.chmodSync(path.join(HOME_INSTALL, 'install.sh'), 0o755);
    fs.chmodSync(path.join(HOME_INSTALL, 'uninstall.sh'), 0o755);
  } catch (_) {
    /* Windows / non-chmod filesystems */
  }
}

function runBash(scriptName, args) {
  const script = path.join(HOME_INSTALL, scriptName);
  if (!fs.existsSync(script)) {
    throw new Error(`missing ${script}; run without --uninstall first`);
  }
  const result = spawnSync('bash', [script, ...args], {
    stdio: 'inherit',
    env: process.env,
  });
  if (result.error) throw result.error;
  return result.status === null ? 1 : result.status;
}

function main(argv) {
  const args = argv.slice(2);
  if (args.includes('-h') || args.includes('--help')) {
    usage();
    return 0;
  }
  if (args.includes('-V') || args.includes('--version')) {
    process.stdout.write(`${VERSION}\n`);
    return 0;
  }

  const uninstall = args.includes('--uninstall');
  const passthrough = args.filter((a) => a !== '--uninstall');

  try {
    if (uninstall) {
      if (!fs.existsSync(path.join(HOME_INSTALL, 'uninstall.sh'))) {
        materialize();
      }
      return runBash('uninstall.sh', passthrough);
    }

    materialize();
    process.stdout.write(`Materialized auditor-suite ${VERSION} at ${HOME_INSTALL}\n`);
    return runBash('install.sh', passthrough);
  } catch (err) {
    process.stderr.write(`${err && err.message ? err.message : err}\n`);
    return 1;
  }
}

process.exitCode = main(process.argv);
