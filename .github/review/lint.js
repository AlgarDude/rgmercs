#!/usr/bin/env node
'use strict';
// Deterministic pattern review for rgmercs pull requests. Looks only at lines
// ADDED between --base and --head, checks them against the helper index and a
// set of conventions the codebase already follows, and reports every hit as a
// challenge with a file:line citation. No model involved; exit code is 0 unless
// --strict is given.
//
//   node .github/review/lint.js --base main --head HEAD --index review/index.json
//   node .github/review/lint.js --base <sha> --head <sha> --format github --out-md report.md

const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const MAX_ANNOTATIONS_PER_LEVEL = 10;

// ---------------------------------------------------------------------------
// Rules. Each returns null, a message string (anchored at the added line), or
// { line, message } to anchor elsewhere in the same file.

const rules = [
    {
        id: 'reuse/helper-name-collision',
        severity: 'warning',
        check(ctx) {
            if (!ctx.index) return null;
            const m = /^\s*local\s+function\s+(\w+)\s*\(/.exec(ctx.code)
                || /^\s*local\s+(\w+)\s*=\s*function\b/.exec(ctx.code)
                || /^function\s+(\w+)\s*\(/.exec(ctx.code);
            if (!m) return null;
            const name = m[1];
            const target = resolveHelper(ctx.index, name, ctx.file);
            if (!target) return null;
            if (bodyCalls(ctx.scanned, ctx.line, target.qualified)) return null;
            return `\`${name}\` duplicates the name of \`${target.qualified}\` (${cite(target)}). Reuse it, or say in the PR why it does not fit.`;
        },
    },
    {
        id: 'reuse/private-helper-elsewhere',
        severity: 'notice',
        check(ctx) {
            if (!ctx.index) return null;
            const m = /^\s*local\s+function\s+(\w+)\s*\(/.exec(ctx.code) || /^\s*local\s+(\w+)\s*=\s*function\b/.exec(ctx.code);
            if (!m) return null;
            const name = m[1].toLowerCase();
            if (GENERIC_LOCAL_NAMES.has(name)) return null;
            const twin = (ctx.index.byLower.get(name) || []).find(e => e.scope === 'local' && e.file !== ctx.file);
            if (!twin) return null;
            return `A private helper named \`${twin.name}\` already exists in ${cite(twin)}. If it does the same job, promote one copy to utils/ instead of keeping two.`;
        },
    },
    {
        id: 'reuse/known-idiom',
        severity: 'warning',
        check(ctx) { return matchIdiom(ctx, 'warning'); },
    },
    {
        id: 'reuse/known-idiom',
        severity: 'notice',
        check(ctx) { return matchIdiom(ctx, 'notice'); },
    },
    {
        id: 'pattern/unguarded-tlo-string-chain',
        severity: 'warning',
        check(ctx) {
            const m = /mq\.TLO\.[\w.]+(?:\([^()]*\))*\(\)\s*:(lower|upper|find|sub|gsub|match|len|rep)\s*\(/.exec(ctx.code);
            if (!m) return null;
            return `A TLO string is chained straight into \`:${m[1]}()\`. If the TLO returns nil this line crashes; guard it as \`(x() or ""):${m[1]}(...)\`.`;
        },
    },
    {
        id: 'pattern/mq-delay-in-render',
        severity: 'warning',
        check(ctx) {
            if (!/\bmq\.delay\s*\(/.test(ctx.code)) return null;
            const fn = enclosingFunction(ctx.scanned, ctx.line);
            if (!fn || !/render/i.test(fn)) return null;
            return `\`mq.delay\` inside \`${fn}\` blocks the ImGui render thread. Move the wait out of the render path.`;
        },
    },
    {
        id: 'pattern/module-level-bare-local',
        severity: 'notice',
        check(ctx) {
            if (!/^local\s+[A-Za-z_]\w*\s*$/.test(ctx.code.trimEnd())) return null;
            return 'Module-level state is declared as `local foo = nil` in this codebase, not bare `local foo`.';
        },
    },
    {
        id: 'style/goto',
        severity: 'warning',
        check(ctx) {
            if (!/\bgoto\b|::\w+::/.test(ctx.code)) return null;
            return 'The codebase has no `goto`/`::continue::`; restructure with a guard clause or an `if` block.';
        },
    },
    {
        id: 'style/em-dash-in-string',
        severity: 'warning',
        check(ctx) {
            if (!ctx.strings.some(s => s.includes('—'))) return null;
            return "Em dash inside a string. MQ's default font renders it as `?`; use a plain hyphen.";
        },
    },
    {
        id: 'style/missing-trailing-comma',
        severity: 'notice',
        check(ctx) {
            if (/\{\s*[^{}]*[^,\s{]\s*\}/.test(ctx.code)) {
                return 'Single-line table literal without a trailing comma. The formatter config is `trailing_table_separator = always`: `{ a = 1, }`.';
            }
            if (/^\s*\}[,)\]]*;?\s*$/.test(ctx.code)) {
                let j = ctx.line - 2;
                while (j >= 0 && ctx.scanned[j].code.trim() === '') j--;
                if (j < 0) return null;
                const prev = ctx.scanned[j].code.trimEnd();
                if (/[,{(\[]\s*$/.test(prev)) return null;
                if (!ctx.addedSet.has(j + 1)) return null;
                return { line: j + 1, message: 'Last entry of a multi-line table has no trailing comma. The formatter config is `trailing_table_separator = always`.' };
            }
            return null;
        },
    },
    {
        id: 'naming/snake-case-local',
        severity: 'notice',
        check(ctx) {
            const m = /^\s*local\s+([a-z][a-z0-9]*_[a-z0-9_]+)\s*=/.exec(ctx.code);
            if (!m) return null;
            return `\`${m[1]}\` is snake_case; locals in this codebase are camelCase.`;
        },
    },
    {
        id: 'style/tab-indent',
        severity: 'notice',
        check(ctx) { return /^\t/.test(ctx.raw) ? 'Tab indentation; the codebase uses 4 spaces.' : null; },
    },
    {
        id: 'style/trailing-whitespace',
        severity: 'notice',
        check(ctx) { return /[ \t]+$/.test(ctx.raw) ? 'Trailing whitespace.' : null; },
    },
    {
        id: 'style/line-too-long',
        severity: 'notice',
        check(ctx) { return ctx.raw.length > 180 ? `Line is ${ctx.raw.length} characters; the formatter limit is 180.` : null; },
    },
];

// Idioms that re-implement something the codebase already routes through a
// helper. `canonical` is looked up in the index at run time so the citation is
// never stale; if the helper is not in the index the message still names it.
const IDIOMS = [
    { re: /\bos\.clock\s*\(/, canonical: null, hint: '`mq.gettime()` (milliseconds since client start) is what the codebase uses for timing, not `os.clock()`.' },
    { re: /\bmq\.cmdf?\s*\(/, canonical: 'Core.DoCmd', exclude: ['utils/core.lua', 'utils/comms.lua'], hint: 'Commands go through `Core.DoCmd` (or `Core.DoGroupCmd` / `Comms.SendPeerDoCmd`), not raw `mq.cmd`.' },
    { re: /^\s*printf?\s*\(/, canonical: null, areas: ['modules', 'class_configs', 'ui'], exclude: ['modules/faq.lua'], hint: 'Output goes through `Logger.log_info` / `log_debug` / `log_error` (generated in `utils/logger.lua`), not `print`/`printf`.' },
    { re: /\bstring\.gmatch\s*\(/, canonical: 'Strings.split', exclude: ['utils/strings.lua', 'utils/signatures.lua'], hint: '`Strings.split` / `Strings.gsplit` already implement pattern splitting.' },
    { re: /setmetatable\(\s*\w+\s*,\s*getmetatable\(/, canonical: 'Tables.DeepCopy', exclude: ['utils/tables.lua'], hint: 'This is the deep-copy idiom; `Tables.DeepCopy` already does it.' },
    { re: /mq\.TLO\.Group\.MainAssist\b/, canonical: 'Core.GetMainAssistId', exclude: ['utils/core.lua'], hint: 'Main-assist lookups go through `Core.GetMainAssistId` / `Core.GetMainAssistSpawn` / `Core.GetGroupMainAssistName`, which also handle raid assist.' },
    { re: /mq\.TLO\.Me\.Class\.ShortName\(\)\s*(==|~=)/, canonical: 'Core.MyClassIs', exclude: ['utils/core.lua'], severity: 'notice', hint: '`Core.MyClassIs("XXX")` is the class comparison the codebase uses.' },
    { re: /\bmq\.TLO\.Me\.(?:Buff|Song)\s*\(/, canonical: 'Core.GetBuffTable', exclude: ['utils/core.lua', 'utils/casting.lua'], severity: 'notice', hint: 'Buff/song scans usually go through `Core.GetBuffTable` / `Core.GetSongTable` or the `Casting` helpers; check there first.' },
];

// Names that many files legitimately define privately; a same-named local in
// another file is not evidence of duplication.
const GENERIC_LOCAL_NAMES = new Set(['init', 'render', 'update', 'reset', 'setup', 'load', 'save', 'main', 'run', 'tick', 'draw', 'handler', 'callback', 'cb', 'helper', 'check', 'validate', 'process', 'apply']);

// Aliases people reach for when they re-implement a helper; resolved against
// the index so the citation is the real current location.
const ALIASES = new Map(Object.entries({
    split: 'Strings.split', splitstring: 'Strings.split', gsplit: 'Strings.gsplit',
    trim: 'Strings.TrimSpaces', trimspaces: 'Strings.TrimSpaces', strip: 'Strings.TrimSpaces',
    startswith: 'Strings.StartsWith', formattime: 'Strings.FormatTime', formattimems: 'Strings.FormatTimeMS',
    booltostring: 'Strings.BoolToString', padstring: 'Strings.PadString', padleft: 'Strings.PadString', padright: 'Strings.PadString',
    tabletostring: 'Strings.TableToString', printtable: 'Tables.PrintTable',
    deepcopy: 'Tables.DeepCopy', copytable: 'Tables.DeepCopy', clonetable: 'Tables.DeepCopy', deepclone: 'Tables.DeepCopy',
    tablesize: 'Tables.GetTableSize', gettablesize: 'Tables.GetTableSize', tablelength: 'Tables.GetTableSize', counttable: 'Tables.GetTableSize', tablecount: 'Tables.GetTableSize',
    tablecontains: 'Tables.TableContains', contains: 'Tables.TableContains', hasvalue: 'Tables.TableContains', intable: 'Tables.TableContains',
    concattables: 'Tables.ConcatTables', mergetables: 'Tables.ConcatTables', tablesequal: 'Tables.AreTablesEqual', aretablesequal: 'Tables.AreTablesEqual',
    safecall: 'Core.SafeCallFunc', safecallfunc: 'Core.SafeCallFunc', docmd: 'Core.DoCmd', settarget: 'Core.SetTarget',
    getpeername: 'Comms.GetPeerName', popup: 'Comms.PopUp',
}));

// ---------------------------------------------------------------------------

main();

function main() {
    const args = parseArgs(process.argv.slice(2));
    if (!args.base || !args.head) die('usage: lint.js --base <rev> --head <rev> [--index index.json] [--repo dir] [--format text|github] [--out-md file] [--out-json file] [--strict]');
    const repo = path.resolve(args.repo || '.');
    const format = args.format || 'text';
    const git = (...a) => execFileSync('git', a, { cwd: repo, encoding: 'utf8', maxBuffer: 256 * 1024 * 1024 }).replace(/\r\n/g, '\n').trimEnd();

    const index = loadIndex(args.index);
    const base = git('rev-parse', args.base);
    const head = git('rev-parse', args.head);
    const diffFiles = parseDiff(git('diff', '-U0', '--no-color', '--diff-filter=AMR', base, head, '--', '*.lua'));

    const findings = [];
    let addedLineCount = 0;
    for (const f of diffFiles) {
        if (skipPath(f.path)) continue;
        const content = git('show', `${head}:${f.path}`);
        const lines = content.split('\n');
        const scanned = scanLua(content);
        const area = areaOf(f.path);
        const addedSet = new Set(f.added.map(a => a.line));

        if (content.length > 0 && !f.endsWithNewline) {
            findings.push(finding('style/missing-final-newline', 'notice', f.path, lines.length, 'File does not end with a newline.'));
        }

        for (const { line } of f.added) {
            addedLineCount++;
            const raw = lines[line - 1];
            if (raw === undefined) continue;
            const info = scanned[line - 1];
            const ctx = { file: f.path, line, raw, code: info.code, strings: info.strings, area, lines, scanned, addedSet, index };
            for (const rule of rules) {
                const msg = rule.check(ctx);
                if (!msg) continue;
                if (typeof msg === 'object') findings.push(finding(rule.id, rule.severity, ctx.file, msg.line, msg.message));
                else findings.push(finding(rule.id, rule.severity, ctx.file, line, msg));
            }
        }
    }

    findings.sort((a, b) => sevRank(a.severity) - sevRank(b.severity) || a.file.localeCompare(b.file) || a.line - b.line);

    const report = {
        base,
        head,
        files: diffFiles.filter(f => !skipPath(f.path)).map(f => f.path),
        addedLines: addedLineCount,
        indexed: index ? index.count : 0,
        findings,
    };
    if (args['out-json']) writeFile(args['out-json'], JSON.stringify(report, null, 1) + '\n');
    if (args['out-md']) writeFile(args['out-md'], renderMarkdown(report));

    if (format === 'github') emitAnnotations(findings);
    else process.stdout.write(renderText(report));

    if (args.strict && findings.some(f => f.severity === 'warning')) process.exit(1);
}

function matchIdiom(ctx, severity) {
    for (const idiom of IDIOMS) {
        if ((idiom.severity || 'warning') !== severity) continue;
        if (idiom.exclude && idiom.exclude.includes(ctx.file)) continue;
        if (idiom.areas && !idiom.areas.includes(ctx.area)) continue;
        if (!idiom.re.test(ctx.code)) continue;
        if (!idiom.canonical || !ctx.index) return idiom.hint;
        const e = ctx.index.byQualified.get(idiom.canonical);
        return e ? `${idiom.hint} See ${cite(e)}.` : idiom.hint;
    }
    return null;
}

function resolveHelper(index, name, currentFile) {
    const lower = name.toLowerCase();
    const alias = ALIASES.get(lower);
    if (alias) {
        const e = index.byQualified.get(alias);
        if (e && e.file !== currentFile) return e;
    }
    const candidates = index.byLower.get(lower) || [];
    return candidates.find(e => e.scope === 'exported' && e.namespace !== 'Module' && e.file !== currentFile) || null;
}

function cite(e) { return `\`${e.file}:${e.line}\``; }

// True if the function starting at `line` calls `qualified` before its closing
// `end` (a thin local wrapper around the helper is not a re-implementation).
function bodyCalls(scanned, line, qualified) {
    const indent = /^\s*/.exec(scanned[line - 1].code)[0];
    for (let j = line; j < Math.min(scanned.length, line + 60); j++) {
        const code = scanned[j].code;
        if (code.includes(qualified + '(')) return true;
        if (new RegExp(`^${indent}end\\b`).test(code)) return false;
    }
    return false;
}

function enclosingFunction(scanned, line) {
    for (let j = line - 2; j >= 0; j--) {
        const code = scanned[j].code;
        let m = /^\s*(?:local\s+)?function\s+([\w.:]+)\s*\(/.exec(code);
        if (m) return m[1];
        m = /^\s*(?:local\s+)?([\w.:]+)\s*=\s*function\s*\(/.exec(code);
        if (m) return m[1];
    }
    return null;
}

function loadIndex(file) {
    if (!file) return null;
    if (!fs.existsSync(file)) die(`index not found: ${file}`);
    const idx = JSON.parse(fs.readFileSync(file, 'utf8'));
    idx.byLower = new Map();
    idx.byQualified = new Map();
    for (const e of idx.entries) {
        const k = e.name.toLowerCase();
        if (!idx.byLower.has(k)) idx.byLower.set(k, []);
        idx.byLower.get(k).push(e);
        if (e.scope === 'exported' && !idx.byQualified.has(e.qualified)) idx.byQualified.set(e.qualified, e);
    }
    return idx;
}

// lib/ is vendored third-party code and is not held to rgmercs conventions.
function skipPath(p) {
    return !p.endsWith('.lua') || p === 'extras/version.lua' || p.startsWith('.github/') || p.startsWith('lib/');
}

function areaOf(p) {
    const top = p.split('/')[0];
    return ['utils', 'modules', 'ui', 'class_configs', 'tests', 'lib', 'extras'].includes(top) ? top : 'root';
}

// Parses `git diff -U0` output into [{ path, added: [{ line, text }], endsWithNewline }].
function parseDiff(text) {
    const files = [];
    let cur = null;
    let newLine = 0;
    let lastWasAdded = false;
    for (const line of text.split('\n')) {
        if (line.startsWith('diff --git ')) {
            cur = { path: null, added: [], binary: false, endsWithNewline: true };
            files.push(cur);
            lastWasAdded = false;
            continue;
        }
        if (!cur) continue;
        if (line.startsWith('--- ')) continue;
        if (line.startsWith('+++ ')) { cur.path = line === '+++ /dev/null' ? null : line.slice(6); continue; }
        if (line.startsWith('Binary files')) { cur.binary = true; continue; }
        const h = /^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/.exec(line);
        if (h) { newLine = parseInt(h[1], 10); lastWasAdded = false; continue; }
        if (line.startsWith('\\')) { if (lastWasAdded) cur.endsWithNewline = false; continue; }
        if (line.startsWith('+')) { cur.added.push({ line: newLine, text: line.slice(1) }); newLine++; lastWasAdded = true; continue; }
        lastWasAdded = false;
        if (line.startsWith('-')) continue;
        if (line.startsWith(' ')) newLine++;
    }
    return files.filter(f => f.path && !f.binary);
}

// Splits a Lua source into per-line { code, strings } where `code` has comments
// removed and string bodies blanked, and `strings` holds the raw string bodies
// that start on that line. Tracks long strings/comments across lines.
function scanLua(src) {
    const lines = src.split('\n');
    const out = [];
    let state = 'code';
    let quote = '';
    let level = 0;
    let cur = '';
    for (const raw of lines) {
        let code = '';
        const strings = [];
        let i = 0;
        if (state === 'str') state = 'code';
        while (i < raw.length) {
            const c = raw[i];
            if (state === 'code') {
                if (c === '-' && raw[i + 1] === '-') {
                    const m = /^--\[(=*)\[/.exec(raw.slice(i));
                    if (m) { state = 'lcom'; level = m[1].length; i += m[0].length; continue; }
                    break;
                }
                if (c === '"' || c === "'") { state = 'str'; quote = c; cur = ''; code += c; i++; continue; }
                if (c === '[') {
                    const m = /^\[(=*)\[/.exec(raw.slice(i));
                    if (m) { state = 'lstr'; level = m[1].length; cur = ''; code += '"'; i += m[0].length; continue; }
                }
                code += c; i++;
            } else if (state === 'str') {
                if (c === '\\') { cur += c + (raw[i + 1] || ''); i += 2; continue; }
                if (c === quote) { strings.push(cur); code += quote; state = 'code'; i++; continue; }
                cur += c; i++;
            } else {
                const close = ']' + '='.repeat(level) + ']';
                if (raw.startsWith(close, i)) {
                    if (state === 'lstr') { strings.push(cur); code += '"'; }
                    state = 'code'; i += close.length; continue;
                }
                if (state === 'lstr') cur += c;
                i++;
            }
        }
        if (state === 'str') { strings.push(cur); state = 'code'; }
        if (state === 'lstr') cur += '\n';
        out.push({ code, strings });
    }
    return out;
}

function finding(rule, severity, file, line, message) { return { rule, severity, file, line, message }; }
function sevRank(s) { return s === 'warning' ? 0 : 1; }

function emitAnnotations(findings) {
    const shown = { warning: 0, notice: 0 };
    for (const f of findings) {
        if (shown[f.severity] >= MAX_ANNOTATIONS_PER_LEVEL) continue;
        shown[f.severity]++;
        process.stdout.write(`::${f.severity} file=${f.file},line=${f.line},title=${f.rule}::${escapeAnnotation(f.message)}\n`);
    }
    const hidden = findings.length - shown.warning - shown.notice;
    if (hidden > 0) process.stdout.write(`::notice title=pattern-review::${hidden} more finding(s) in the PR comment and step summary.\n`);
}

function escapeAnnotation(s) { return s.replace(/%/g, '%25').replace(/\r/g, '%0D').replace(/\n/g, '%0A'); }

function renderText(r) {
    const out = [`pattern-review: ${r.addedLines} added lines in ${r.files.length} file(s), ${r.base.slice(0, 7)}..${r.head.slice(0, 7)}, index ${r.indexed} helpers`];
    if (!r.findings.length) out.push('  no findings');
    for (const f of r.findings) out.push(`  ${f.severity === 'warning' ? 'WARN' : 'note'} ${f.file}:${f.line} [${f.rule}] ${f.message}`);
    return out.join('\n') + '\n';
}

function renderMarkdown(r) {
    const warnings = r.findings.filter(f => f.severity === 'warning');
    const notices = r.findings.filter(f => f.severity === 'notice');
    const out = ['<!-- rgmercs-pattern-review -->', '## Pattern review', ''];
    out.push(`Checked ${r.addedLines} added line(s) in ${r.files.length} Lua file(s) against \`${r.base.slice(0, 7)}\` (${r.indexed} indexed helpers). Deterministic pass, no model involved.`, '');
    if (!r.findings.length) {
        out.push('No challenges. Nothing added here collides with an existing helper or a convention the codebase follows.', '');
    }
    if (warnings.length) {
        out.push(`### Challenges (${warnings.length})`, '', 'Each row claims something already exists or a convention was skipped. Answer it in the PR or change the code.', '');
        out.push('| Where | Rule | Challenge |', '|---|---|---|');
        for (const f of warnings) out.push(`| \`${f.file}:${f.line}\` | \`${f.rule}\` | ${f.message.replace(/\|/g, '\\|')} |`);
        out.push('');
    }
    if (notices.length) {
        out.push('<details>', `<summary>Style notes (${notices.length})</summary>`, '', '| Where | Rule | Note |', '|---|---|---|');
        for (const f of notices) out.push(`| \`${f.file}:${f.line}\` | \`${f.rule}\` | ${f.message.replace(/\|/g, '\\|')} |`);
        out.push('', '</details>', '');
    }
    out.push('<sub>Rules live in `.github/review/lint.js`. Run locally: `node .github/review/build-index.js --out /tmp/index.json && node .github/review/lint.js --base main --head HEAD --index /tmp/index.json`</sub>', '');
    return out.join('\n');
}

function writeFile(p, content) { fs.mkdirSync(path.dirname(path.resolve(p)), { recursive: true }); fs.writeFileSync(p, content); }
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
