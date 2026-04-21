#!/usr/bin/env node
// remember.ts — capture a skill-shaped learning as an experimental skill
// in MajorLift/metamask-extension-skills under domains/inbox/.
//
// Usage: node remember.ts [flags] "capture text"
//
// Flags:
//   --captured-by <user>  Override author (default: gh api user --jq .login)
//   --source-repo <name>  Override source repo (default: basename of git toplevel)
//   --audit-url <url>     Optional audit backlink (e.g. PR comment URL)
//   --mode <commit|local> commit = PUT to skills repo (default)
//                         local  = write skill.md under --out-dir, no network write
//   --out-dir <dir>       Root dir for --mode local (default: current dir)
//
// Runs on any Node with TypeScript type-stripping support
// (Node 22.6+ with --experimental-strip-types, 23.6+ / 24+ by default).
// Requires: gh CLI authenticated with write access to the skills repo (commit mode only).

import { execFileSync } from 'node:child_process'
import { writeFileSync, mkdirSync, existsSync, readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'

type Mode = 'commit' | 'local'

interface Args {
  capture: string
  capturedBy?: string
  sourceRepo?: string
  auditUrl?: string
  mode: Mode
  outDir?: string
}

const REPO = 'MajorLift/metamask-extension-skills'

function parseArgs(argv: string[]): Args {
  let mode: Mode = 'commit'
  let capturedBy: string | undefined
  let sourceRepo: string | undefined
  let auditUrl: string | undefined
  let outDir: string | undefined
  const positional: string[] = []

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]
    switch (arg) {
      case '--captured-by':
        capturedBy = argv[++i]
        break
      case '--source-repo':
        sourceRepo = argv[++i]
        break
      case '--audit-url':
        auditUrl = argv[++i]
        break
      case '--mode': {
        const m = argv[++i]
        if (m !== 'commit' && m !== 'local') {
          throw new Error(`--mode must be 'commit' or 'local' (got '${m}')`)
        }
        mode = m
        break
      }
      case '--out-dir':
        outDir = argv[++i]
        break
      case '--':
        positional.push(...argv.slice(i + 1))
        i = argv.length
        break
      default:
        if (arg.startsWith('-')) throw new Error(`Unknown flag: ${arg}`)
        positional.push(arg)
    }
  }

  const capture = positional.join(' ').trim()
  if (!capture) {
    throw new Error('Usage: node remember.ts [flags] "capture text"')
  }
  return { capture, capturedBy, sourceRepo, auditUrl, mode, outDir }
}

function run(cmd: string, args: string[]): string {
  return execFileSync(cmd, args, { encoding: 'utf8' }).trim()
}

function runSafe(cmd: string, args: string[]): string | null {
  try {
    return run(cmd, args)
  } catch {
    return null
  }
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 40)
    .replace(/-+$/, '')
}

function describe(text: string): string {
  return text.replace(/\s+/g, ' ').slice(0, 80).trimEnd()
}

function title(text: string): string {
  return text
    .slice(0, 100)
    .replace(/\.$/, '')
    .replace(/\s+/g, ' ')
    .trim()
}

function detectSourceRepo(override?: string): string {
  if (override) return override
  const root = runSafe('git', ['rev-parse', '--show-toplevel'])
  if (!root) return 'unknown'
  return root.split('/').pop() || 'unknown'
}

function resolveCapturedBy(override?: string): string {
  if (override) return override
  return run('gh', ['api', 'user', '--jq', '.login'])
}

function warnIfStale(): void {
  if (!existsSync('.skills/VERSION')) return
  const version = readFileSync('.skills/VERSION', 'utf8')
  const match = version.match(/^synced_at=(.+)$/m)
  if (!match) return
  const syncedAt = new Date(match[1])
  if (Number.isNaN(syncedAt.getTime())) return
  const ageDays = Math.floor((Date.now() - syncedAt.getTime()) / 86_400_000)
  if (ageDays > 3) {
    console.error(
      `⚠  Skills last synced ${ageDays}d ago. Run \`yarn skills:sync\` before capturing.`,
    )
  }
}

function buildBody(args: {
  slug: string
  title: string
  description: string
  capturedBy: string
  capturedAt: string
  sourceRepo: string
  auditUrl?: string
  capture: string
}): string {
  const frontmatter = [
    'maturity: experimental',
    `name: ${args.slug}`,
    `description: ${args.description}`,
    'origin: captured',
    `captured_by: ${args.capturedBy}`,
    `captured_at: ${args.capturedAt}`,
    `source_repo: ${args.sourceRepo}`,
    ...(args.auditUrl ? [`audit_url: ${args.auditUrl}`] : []),
  ].join('\n')

  return [
    '---',
    frontmatter,
    '---',
    '',
    `# ${args.title}`,
    '',
    '## Capture',
    args.capture,
    '',
    '## When To Use',
    'TODO — shepherd to fill in during curation.',
    '',
    '## Do Not Use When',
    'TODO — shepherd to fill in during curation.',
    '',
    '## Notes',
    'Experimental capture. Awaiting curation.',
    '',
    '## Changelog',
    `- ${args.capturedAt} | ${args.capturedBy} | capture | ${args.description}`,
    '',
  ].join('\n')
}

function resolveUniquePath(baseSlug: string): { slug: string; path: string } {
  let slug = baseSlug
  let path = `domains/inbox/skills/${slug}/skill.md`
  for (let n = 2; n <= 20; n++) {
    if (!runSafe('gh', ['api', `repos/${REPO}/contents/${path}`])) {
      return { slug, path }
    }
    slug = `${baseSlug}-${n}`.slice(0, 40).replace(/-+$/, '')
    path = `domains/inbox/skills/${slug}/skill.md`
  }
  throw new Error('Too many slug collisions')
}

function main(): void {
  const args = parseArgs(process.argv.slice(2))

  if (args.mode === 'commit') warnIfStale()

  const sourceRepo = detectSourceRepo(args.sourceRepo)
  const baseSlug = slugify(args.capture)
  if (!baseSlug) throw new Error('Capture produced empty slug')

  const description = describe(args.capture)
  const capturedBy = resolveCapturedBy(args.capturedBy)
  const capturedAt = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z')
  const skillTitle = title(args.capture)

  const { slug, path } = resolveUniquePath(baseSlug)

  const body = buildBody({
    slug,
    title: skillTitle,
    description,
    capturedBy,
    capturedAt,
    sourceRepo,
    auditUrl: args.auditUrl,
    capture: args.capture,
  })

  if (args.mode === 'local') {
    const outDir = args.outDir ?? process.cwd()
    const fullPath = resolve(outDir, path)
    mkdirSync(dirname(fullPath), { recursive: true })
    writeFileSync(fullPath, body)
    console.log(`SKILL_PATH=${path}`)
    console.log(`SKILL_SLUG=${slug}`)
    console.log(`SKILL_DESCRIPTION=${description}`)
    console.log(`SKILL_FULL_PATH=${fullPath}`)
    return
  }

  const contentB64 = Buffer.from(body, 'utf8').toString('base64')
  const response = run('gh', [
    'api',
    `repos/${REPO}/contents/${path}`,
    '--method',
    'PUT',
    '-f',
    `message=capture(inbox/${slug}): ${description}`,
    '-f',
    `content=${contentB64}`,
  ])
  const parsed = JSON.parse(response) as {
    commit: { sha: string }
    content: { html_url: string }
  }
  const short = parsed.commit.sha.slice(0, 7)
  const url = parsed.content.html_url
  console.log(`✓ ${path} — ${short} — ${url}`)
}

try {
  main()
} catch (err) {
  console.error(err instanceof Error ? err.message : String(err))
  process.exit(1)
}
