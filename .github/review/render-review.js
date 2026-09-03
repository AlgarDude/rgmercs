#!/usr/bin/env node
'use strict';
// Appends the model pass to the pattern-review comment. Reads the reviewer's
// structured output and, if present, the refuter's verdicts; findings the
// refuter knocked down are kept but collapsed. When the model pass did not run,
// writes a one-line note saying why.
//   node .github/review/render-review.js --report review/report.md --findings review/findings.json
//        [--verdicts review/verdicts.json] [--model claude-opus-5] [--skipped "reason"]

const fs = require('fs');

const args = parseArgs(process.argv.slice(2));
if (!args.report) die('usage: render-review.js --report report.md [--findings findings.json] [--verdicts verdicts.json] [--model name] [--skipped reason]');

const out = ['', '### Model review', ''];

if (args.skipped || !args.findings || !fs.existsSync(args.findings)) {
    out.push(`_Model pass skipped: ${args.skipped || 'no findings file produced'}._`, '');
} else {
    const review = readJson(args.findings);
    const findings = Array.isArray(review.findings) ? review.findings : [];
    const verdicts = args.verdicts && fs.existsSync(args.verdicts) ? readJson(args.verdicts).verdicts || [] : null;
    const verdictFor = i => (verdicts || []).find(v => v.index === i) || null;

    const standing = [];
    const refuted = [];
    findings.forEach((f, i) => {
        const v = verdictFor(i);
        if (v && v.verdict === 'refuted') refuted.push({ ...f, reason: v.reason });
        else standing.push({ ...f, reason: v ? v.reason : null });
    });

    const model = args.model ? ` by \`${args.model}\`` : '';
    const passes = verdicts ? 'two passes: one arguing each finding, one trying to refute it' : 'one pass';
    out.push(`Adversarial read of the diff against the base tree${model}, ${passes}. Every claim cites something the model opened.`, '');
    if (typeof review.summary === 'string' && review.summary.trim()) out.push(`> ${review.summary.trim()}`, '');

    if (!standing.length) {
        out.push(refuted.length ? 'No findings survived refutation.' : 'No findings.', '');
    } else {
        out.push(`#### Challenges that stand (${standing.length})`, '', '| Where | Claim | Already exists | Evidence |', '|---|---|---|---|');
        for (const f of standing) {
            const conf = f.confidence === 'medium' ? ' _(medium confidence)_' : '';
            out.push(`| \`${cell(f.file)}:${f.line}\` | ${cell(f.claim)}${conf} | ${cell(f.existing)} | ${cell(f.evidence)}${f.reason ? ` Defence: ${cell(f.reason)}` : ''} |`);
        }
        out.push('');
    }
    if (refuted.length) {
        out.push('<details>', `<summary>Refuted by the second pass (${refuted.length})</summary>`, '', '| Where | Claim | Why it was dropped |', '|---|---|---|');
        for (const f of refuted) out.push(`| \`${cell(f.file)}:${f.line}\` | ${cell(f.claim)} | ${cell(f.reason)} |`);
        out.push('', '</details>', '');
    }
}

const report = fs.readFileSync(args.report, 'utf8');
const marker = '<sub>Rules live in';
const at = report.lastIndexOf(marker);
const merged = at >= 0 ? report.slice(0, at) + out.join('\n') + '\n' + report.slice(at) : report + out.join('\n') + '\n';
fs.writeFileSync(args.report, merged);

function cell(s) { return String(s == null ? '' : s).replace(/\|/g, '\\|').replace(/\r?\n/g, ' ').trim(); }
function readJson(p) { return JSON.parse(fs.readFileSync(p, 'utf8')); }
function die(msg) { process.stderr.write(msg + '\n'); process.exit(2); }
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
