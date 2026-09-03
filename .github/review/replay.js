#!/usr/bin/env node
'use strict';
// Replays the pattern review over merged pull requests in local history, with
// the helper index rebuilt from each PR's own base commit. Used to calibrate
// rules against what was actually merged.
//   node .github/review/replay.js [--since 2026-01-01] [--limit 50] [--out replay.json]

const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const args = parseArgs(process.argv.slice(2));
const here = __dirname;
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'rgmercs-replay-'));
const git = (...a) => execFileSync('git', a, { encoding: 'utf8', maxBuffer: 256 * 1024 * 1024 }).replace(/\r\n/g, '\n').trimEnd();

const logArgs = ['log', '--first-parent', '--format=%H\t%ad\t%s', '--date=short'];
if (args.since) logArgs.push(`--since=${args.since}`);
let commits = git(...logArgs).split('\n').map(l => {
    const [sha, date, subject] = l.split('\t');
    const m = /\(#(\d+)\)\s*$/.exec(subject) || /Merge pull request #(\d+)/.exec(subject);
    return m ? { sha, date, pr: parseInt(m[1], 10), subject } : null;
}).filter(Boolean);
if (args.limit) commits = commits.slice(0, parseInt(args.limit, 10));

const results = [];
const started = Date.now();
for (let i = 0; i < commits.length; i++) {
    const c = commits[i];
    const indexFile = path.join(tmp, 'index.json');
    const reportFile = path.join(tmp, 'report.json');
    try {
        execFileSync('node', [path.join(here, 'build-index.js'), '--rev', `${c.sha}^`, '--out', indexFile, '--quiet'], { stdio: 'pipe' });
        execFileSync('node', [path.join(here, 'lint.js'), '--base', `${c.sha}^`, '--head', c.sha, '--index', indexFile, '--out-json', reportFile], { stdio: 'pipe' });
        const r = JSON.parse(fs.readFileSync(reportFile, 'utf8'));
        results.push({ ...c, files: r.files.length, addedLines: r.addedLines, findings: r.findings });
    } catch (err) {
        results.push({ ...c, error: String(err.stderr || err.message).trim().split('\n').pop() });
    }
    if ((i + 1) % 25 === 0 || i === commits.length - 1) {
        process.stderr.write(`${i + 1}/${commits.length} (${Math.round((Date.now() - started) / 1000)}s)\n`);
    }
}
fs.rmSync(tmp, { recursive: true, force: true });

const ok = results.filter(r => !r.error);
const byRule = {};
for (const r of ok) for (const f of r.findings) byRule[f.rule] = (byRule[f.rule] || 0) + 1;
const withWarnings = ok.filter(r => r.findings.some(f => f.severity === 'warning'));
const summary = {
    prs: results.length,
    errors: results.filter(r => r.error).length,
    prsWithWarnings: withWarnings.length,
    prsWithAnyFinding: ok.filter(r => r.findings.length).length,
    addedLines: ok.reduce((n, r) => n + r.addedLines, 0),
    byRule: Object.fromEntries(Object.entries(byRule).sort((a, b) => b[1] - a[1])),
};

if (args.out) fs.writeFileSync(args.out, JSON.stringify({ summary, results }, null, 1) + '\n');
process.stdout.write(JSON.stringify(summary, null, 2) + '\n');

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
