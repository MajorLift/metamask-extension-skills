#!/usr/bin/env node
// remember.ts — capture or amend a skill-shaped learning in
// MajorLift/metamask-extension-skills. New captures land under
// domains/inbox/; amendments edit an existing skill in place.
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
//   --body-file <path>    Pre-shaped markdown body for the skill (headings below
//                         the H1 title). Replaces the TODO template when creating
//                         a new skill; appended as an amendment when editing.
//   --domain <name>       Route new capture to domains/<name>/skills/<slug>/.
//                         Required for new captures; agents pick domain at
//                         capture time alongside shaping and new-vs-edit.
//                         Fallback to `inbox` emits a follow-up warning.
//   --edit <path>         Edit an existing skill at <path> (e.g.
//                         domains/<x>/skills/<slug>/skill.md) instead of creating
//                         a new one. Adds a changelog entry and, when
//                         --body-file is given, an amendment section.
//
// Runs on any Node with TypeScript type-stripping support
// (Node 22.6+ with --experimental-strip-types, 23.6+ / 24+ by default).
// Requires: gh CLI authenticated with write access to the skills repo.

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
  bodyFile?: string
  editPath?: string
  domain?: string
}

const REPO = 'MajorLift/metamask-extension-skills'

function parseArgs(argv: string[]): Args {
  let mode: Mode = 'commit'
  let capturedBy: string | undefined
  let sourceRepo: string | undefined
  let auditUrl: string | undefined
  let outDir: string | undefined
  let bodyFile: string | undefined
  let editPath: string | undefined
  let domain: string | undefined
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
      case '--body-file':
        bodyFile = argv[++i]
        break
      case '--edit':
        editPath = argv[++i]
        break
      case '--domain':
        domain = argv[++i]
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
  return {
    capture,
    capturedBy,
    sourceRepo,
    auditUrl,
    mode,
    outDir,
    bodyFile,
    editPath,
    domain,
  }
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

function readBodyFile(path?: string): string | null {
  if (!path) return null
  return readFileSync(path, 'utf8').trimEnd()
}

function defaultBody(capture: string): string {
  return [
    '## Capture',
    capture,
    '',
    '## When To Use',
    'TODO — shape at capture time. Shaping deferred is shaping abandoned.',
    '',
    '## Do Not Use When',
    'TODO — shape at capture time. Shaping deferred is shaping abandoned.',
    '',
    '## Notes',
    'Experimental capture. Body unshaped — prefer passing --body-file next time.',
  ].join('\n')
}

function buildNewSkill(args: {
  slug: string
  title: string
  description: string
  capturedBy: string
  capturedAt: string
  sourceRepo: string
  auditUrl?: string
  capture: string
  shapedBody: string | null
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

  const body = args.shapedBody ?? defaultBody(args.capture)

  return [
    '---',
    frontmatter,
    '---',
    '',
    `# ${args.title}`,
    '',
    body,
    '',
    '## Changelog',
    `- ${args.capturedAt} | ${args.capturedBy} | capture | ${args.description}`,
    '',
  ].join('\n')
}

function buildAmendment(args: {
  capturedBy: string
  capturedAt: string
  description: string
  capture: string
  sourceRepo: string
  auditUrl?: string
  shapedBody: string | null
}): { amendment: string; changelogEntry: string } {
  const heading = `## Amendment ${args.capturedAt}`
  const trailer = [
    `_${args.capturedBy} from ${args.sourceRepo}${args.auditUrl ? ` — [context](${args.auditUrl})` : ''}_`,
  ].join('\n')

  const body = args.shapedBody
    ? `${args.shapedBody}\n\n${trailer}`
    : `${args.capture}\n\n${trailer}`

  const amendment = [heading, '', body, ''].join('\n')
  const changelogEntry = `- ${args.capturedAt} | ${args.capturedBy} | amend | ${args.description}`
  return { amendment, changelogEntry }
}

function applyAmendment(
  existing: string,
  amendment: string,
  changelogEntry: string,
): string {
  // Insert amendment section just before the Changelog heading (or at EOF if absent),
  // and append changelog entry to the Changelog list.
  const changelogRe = /\n## Changelog\b/
  const match = existing.match(changelogRe)

  if (!match || match.index === undefined) {
    // No Changelog — append one along with the amendment.
    return `${existing.trimEnd()}\n\n${amendment}\n## Changelog\n${changelogEntry}\n`
  }

  const before = existing.slice(0, match.index).trimEnd()
  const changelogBlock = existing.slice(match.index).trimEnd()
  return `${before}\n\n${amendment}\n${changelogBlock}\n${changelogEntry}\n`
}

function resolveUniquePath(
  baseSlug: string,
  domain: string,
): { slug: string; path: string; collided: boolean } {
  let slug = baseSlug
  let path = `domains/${domain}/skills/${slug}/skill.md`
  for (let n = 2; n <= 20; n++) {
    if (!runSafe('gh', ['api', `repos/${REPO}/contents/${path}`])) {
      return { slug, path, collided: slug !== baseSlug }
    }
    slug = `${baseSlug}-${n}`.slice(0, 40).replace(/-+$/, '')
    path = `domains/${domain}/skills/${slug}/skill.md`
  }
  throw new Error('Too many slug collisions')
}

function emitFollowUps(followUps: string[]): void {
  if (followUps.length === 0) return
  console.log('')
  console.log('Follow-ups:')
  for (const item of followUps) console.log(`- ${item}`)
}

function fetchRemote(
  path: string,
): { content: string; sha: string; htmlUrl: string } | null {
  const raw = runSafe('gh', [
    'api',
    `repos/${REPO}/contents/${path}`,
    '--jq',
    '{content,sha,html_url}',
  ])
  if (!raw) return null
  const parsed = JSON.parse(raw) as {
    content: string
    sha: string
    html_url: string
  }
  const content = Buffer.from(parsed.content, 'base64').toString('utf8')
  return { content, sha: parsed.sha, htmlUrl: parsed.html_url }
}

function main(): void {
  const args = parseArgs(process.argv.slice(2))

  if (args.mode === 'commit') warnIfStale()

  const sourceRepo = detectSourceRepo(args.sourceRepo)
  const description = describe(args.capture)
  const capturedBy = resolveCapturedBy(args.capturedBy)
  const capturedAt = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z')
  const shapedBody = readBodyFile(args.bodyFile)

  if (args.editPath) {
    runEdit({
      editPath: args.editPath,
      mode: args.mode,
      outDir: args.outDir,
      capture: args.capture,
      description,
      capturedBy,
      capturedAt,
      sourceRepo,
      auditUrl: args.auditUrl,
      shapedBody,
    })
    return
  }

  runNew({
    mode: args.mode,
    outDir: args.outDir,
    capture: args.capture,
    description,
    capturedBy,
    capturedAt,
    sourceRepo,
    auditUrl: args.auditUrl,
    shapedBody,
    domain: args.domain,
  })
}

function runNew(args: {
  mode: Mode
  outDir?: string
  capture: string
  description: string
  capturedBy: string
  capturedAt: string
  sourceRepo: string
  auditUrl?: string
  shapedBody: string | null
  domain?: string
}): void {
  const baseSlug = slugify(args.capture)
  if (!baseSlug) throw new Error('Capture produced empty slug')
  const skillTitle = title(args.capture)

  const followUps: string[] = []
  if (!args.shapedBody) {
    followUps.push(
      'Body is TODO placeholders. Shape the body before this stub rots.',
    )
  }

  const domain = args.domain ?? 'inbox'
  if (!args.domain) {
    followUps.push(
      "No --domain passed — falling back to 'inbox'. Inbox has no curator; pick a domain at capture so the skill ships to the bundle.",
    )
  }

  if (args.mode === 'local') {
    const slug = baseSlug
    const path = `domains/${domain}/skills/${slug}/skill.md`
    const body = buildNewSkill({ ...args, slug, title: skillTitle })
    const outDir = args.outDir ?? process.cwd()
    const fullPath = resolve(outDir, path)
    mkdirSync(dirname(fullPath), { recursive: true })
    writeFileSync(fullPath, body)
    console.log(`SKILL_PATH=${path}`)
    console.log(`SKILL_SLUG=${slug}`)
    console.log(`SKILL_DESCRIPTION=${args.description}`)
    console.log(`SKILL_FULL_PATH=${fullPath}`)
    emitFollowUps(followUps)
    return
  }

  const { slug, path, collided } = resolveUniquePath(baseSlug, domain)
  if (collided) {
    followUps.push(
      `Slug collided with existing skill — using '${slug}' instead of '${baseSlug}'. Verify this isn't a near-duplicate before promotion.`,
    )
  }
  const body = buildNewSkill({ ...args, slug, title: skillTitle })
  const contentB64 = Buffer.from(body, 'utf8').toString('base64')
  const response = run('gh', [
    'api',
    `repos/${REPO}/contents/${path}`,
    '--method',
    'PUT',
    '-f',
    `message=capture(${domain}/${slug}): ${args.description}`,
    '-f',
    `content=${contentB64}`,
  ])
  const parsed = JSON.parse(response) as {
    commit: { sha: string }
    content: { html_url: string }
  }
  console.log(`✓ ${path} — ${parsed.commit.sha.slice(0, 7)} — ${parsed.content.html_url}`)
  emitFollowUps(followUps)
}

function runEdit(args: {
  editPath: string
  mode: Mode
  outDir?: string
  capture: string
  description: string
  capturedBy: string
  capturedAt: string
  sourceRepo: string
  auditUrl?: string
  shapedBody: string | null
}): void {
  const { amendment, changelogEntry } = buildAmendment(args)
  const followUps: string[] = []
  if (!args.shapedBody) {
    followUps.push(
      'Amendment body is only the capture one-liner. Consider whether parent sections need updating.',
    )
  }

  if (args.mode === 'local') {
    const outDir = args.outDir ?? process.cwd()
    const fullPath = resolve(outDir, args.editPath)
    if (!existsSync(fullPath)) {
      throw new Error(`--edit target not found locally: ${fullPath}`)
    }
    const existing = readFileSync(fullPath, 'utf8')
    const updated = applyAmendment(existing, amendment, changelogEntry)
    writeFileSync(fullPath, updated)
    console.log(`SKILL_PATH=${args.editPath}`)
    console.log(`SKILL_MODE=edit`)
    console.log(`SKILL_DESCRIPTION=${args.description}`)
    console.log(`SKILL_FULL_PATH=${fullPath}`)
    emitFollowUps(followUps)
    return
  }

  const remote = fetchRemote(args.editPath)
  if (!remote) throw new Error(`--edit target not found: ${args.editPath}`)
  const updated = applyAmendment(remote.content, amendment, changelogEntry)
  const contentB64 = Buffer.from(updated, 'utf8').toString('base64')
  const response = run('gh', [
    'api',
    `repos/${REPO}/contents/${args.editPath}`,
    '--method',
    'PUT',
    '-f',
    `message=amend(${args.editPath}): ${args.description}`,
    '-f',
    `content=${contentB64}`,
    '-f',
    `sha=${remote.sha}`,
  ])
  const parsed = JSON.parse(response) as {
    commit: { sha: string }
    content: { html_url: string }
  }
  console.log(
    `✓ ${args.editPath} — ${parsed.commit.sha.slice(0, 7)} — ${parsed.content.html_url}`,
  )
  emitFollowUps(followUps)
}

try {
  main()
} catch (err) {
  console.error(err instanceof Error ? err.message : String(err))
  process.exit(1)
}
