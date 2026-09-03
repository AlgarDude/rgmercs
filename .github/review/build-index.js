#!/usr/bin/env node
'use strict';
// Builds an index of every function defined in the rgmercs Lua tree so a
// reviewer (script or model) can answer "does a helper for this already exist?"
// with a file:line citation instead of a guess. Run from the repo root:
//   node .github/review/build-index.js --out review/index.json --markdown review/index.md
//   node .github/review/build-index.js --rev origin/main --out review/index.json   (read a git revision instead of the working tree)

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const args = parseArgs(process.argv.slice(2));
const root = path.resolve(args.root || '.');
const scanDirs = ['utils', 'modules', 'ui', 'lib', 'extras'];
const scanFiles = ['init.lua', 'heartbeat.lua'];

const exportedRe = /^function\s+([A-Za-z_]\w*)([.:])([A-Za-z_]\w*)\s*\(([^)]*)\)/;
const assignedRe = /^([A-Za-z_]\w*)([.:])([A-Za-z_]\w*)\s*=\s*function\s*\(([^)]*)\)/;
const localFnRe = /^\s*local\s+function\s+([A-Za-z_]\w*)\s*\(([^)]*)\)/;
const localAssignRe = /^\s*local\s+([A-Za-z_]\w*)\s*=\s*function\s*\(([^)]*)\)/;

const sources = args.rev ? readFromGit(args.rev) : readFromDisk();

const entries = [];
for (const { rel, content } of sources) {
    const lines = content.split('\n');
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        let m;
        if ((m = exportedRe.exec(line) || assignedRe.exec(line))) {
            entries.push(entry(m[1], m[2], m[3], m[4], 'exported', rel, i + 1, lines, i));
        } else if ((m = localFnRe.exec(line) || localAssignRe.exec(line))) {
            entries.push(entry(null, null, m[1], m[2], 'local', rel, i + 1, lines, i));
        }
    }
}

const index = {
    root: path.basename(root),
    rev: args.rev || null,
    generatedAt: new Date().toISOString(),
    fileCount: sources.length,
    count: entries.length,
    entries,
};

if (args.out) {
    fs.mkdirSync(path.dirname(path.resolve(args.out)), { recursive: true });
    fs.writeFileSync(args.out, JSON.stringify(index, null, 1) + '\n');
}
if (args.markdown) {
    fs.mkdirSync(path.dirname(path.resolve(args.markdown)), { recursive: true });
    fs.writeFileSync(args.markdown, renderMarkdown(index));
}
if (!args.out && !args.markdown) process.stdout.write(JSON.stringify(index, null, 1) + '\n');
if (!args.quiet) process.stderr.write(`indexed ${entries.length} functions across ${sources.length} files\n`);

function readFromDisk() {
    const files = [];
    for (const dir of scanDirs) walk(path.join(root, dir), files);
    for (const f of scanFiles) if (fs.existsSync(path.join(root, f))) files.push(path.join(root, f));
    files.sort();
    return files.map(abs => ({
        rel: path.relative(root, abs).split(path.sep).join('/'),
        content: fs.readFileSync(abs, 'utf8').replace(/\r\n/g, '\n'),
    }));
}

// Reads the same file set out of a git revision using one ls-tree and one
// cat-file --batch call, so per-PR replays do not need a checkout.
function readFromGit(rev) {
    const listing = execFileSync('git', ['ls-tree', '-r', '--name-only', rev, '--', ...scanDirs, ...scanFiles], { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
    const paths = listing.split('\n').filter(p => p.endsWith('.lua')).sort();
    const batch = execFileSync('git', ['cat-file', '--batch'], { cwd: root, input: paths.map(p => `${rev}:${p}`).join('\n') + '\n', maxBuffer: 256 * 1024 * 1024 });
    const out = [];
    let pos = 0;
    for (const rel of paths) {
        const nl = batch.indexOf(0x0a, pos);
        const header = batch.slice(pos, nl).toString('utf8');
        const parts = header.split(' ');
        if (parts[1] !== 'blob') { pos = nl + 1; continue; }
        const size = parseInt(parts[2], 10);
        const content = batch.slice(nl + 1, nl + 1 + size).toString('utf8').replace(/\r\n/g, '\n');
        pos = nl + 1 + size + 1;
        out.push({ rel, content });
    }
    return out;
}

function entry(namespace, sep, name, params, scope, file, line, lines, i) {
    return {
        namespace,
        sep,
        name,
        qualified: namespace ? `${namespace}${sep}${name}` : name,
        params: params.trim(),
        scope,
        file,
        line,
        doc: collectDoc(lines, i),
    };
}

// First sentence of the `---` block directly above a definition, skipping ---@tags.
function collectDoc(lines, i) {
    const block = [];
    for (let j = i - 1; j >= 0; j--) {
        const t = lines[j].trim();
        if (!t.startsWith('---')) break;
        block.unshift(t.replace(/^-+\s?/, ''));
    }
    const summary = block.find(l => !l.startsWith('@'));
    return summary ? summary.trim() : '';
}

function walk(dir, out) {
    if (!fs.existsSync(dir)) return;
    for (const name of fs.readdirSync(dir)) {
        const abs = path.join(dir, name);
        const st = fs.statSync(abs);
        if (st.isDirectory()) walk(abs, out);
        else if (name.endsWith('.lua')) out.push(abs);
    }
}

function renderMarkdown(index) {
    const byFile = new Map();
    for (const e of index.entries) {
        if (!byFile.has(e.file)) byFile.set(e.file, []);
        byFile.get(e.file).push(e);
    }
    const out = [`# rgmercs helper index`, ``, `${index.count} functions in ${index.fileCount} files.`, ``];
    for (const [file, list] of byFile) {
        out.push(`## ${file}`, ``);
        for (const e of list) {
            const scope = e.scope === 'local' ? ' _(local)_' : '';
            const doc = e.doc ? ` - ${e.doc}` : '';
            out.push(`- \`${e.qualified}(${e.params})\` :${e.line}${scope}${doc}`);
        }
        out.push(``);
    }
    return out.join('\n');
}

function parseArgs(argv) {
    const out = {};
    for (let i = 0; i < argv.length; i++) {
        const a = argv[i];
        if (!a.startsWith('--')) continue;
        const key = a.slice(2);
        const next = argv[i + 1];
        if (next === undefined || next.startsWith('--')) out[key] = true;
        else { out[key] = next; i++; }
    }
    return out;
}
