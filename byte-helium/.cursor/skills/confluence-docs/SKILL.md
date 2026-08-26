---
name: confluence-docs
description: Read Atlassian Confluence pages from the terminal with acli — resolve a page ID from a URL, fetch the body, walk a page tree, and turn the XHTML into plain text. Use when the user pastes a Confluence link, says "read this Confluence page", "what does the spec say", "check the docs on Confluence", or asks for the content of a wiki page.
---

# Reading Confluence with acli

`acli` is the Atlassian CLI (`brew install atlassian/tap/acli`). This skill covers **reading** Confluence content. Writing is a different job — for posting a work log, use the `confluence-personal` skill.

## What acli can and can't do

| Need | Command | Notes |
|---|---|---|
| Read a page | `acli confluence page view --id <id>` | The only page command that exists |
| Read a blog post | `acli confluence blog view --id <id>` | |
| Find blog posts by title | `acli confluence blog list --space-id <id> --title "..."` | Blogs only |
| List spaces | `acli confluence space list` | |

- **There is no search.** No `page search`, no `page list`, no way to look a page up by title. You need the page ID — see below.
- **There is no page create or update.** Only blog posts can be created (see `confluence-personal`).
- `acli confluence space list --keys ...` is **silently ignored** — it returns the first N spaces whatever you pass. Filter locally.
- Confluence auth is separate from Jira auth. Check `acli confluence auth status`; if unauthorised, ask the user to run `! acli confluence auth login` — it is interactive OAuth, you cannot do it for them.

## Getting the page ID

Almost always from the URL the user pasted:

```
https://<site>.atlassian.net/wiki/spaces/YUM/pages/1220019192/Admin+Portal
                                                   ^^^^^^^^^^ the ID
```

Short `/wiki/x/cYCsAw` links carry no ID — ask the user to open it and paste the full URL.

No URL at all? Walk down from the space:

```bash
acli confluence space list --limit 250 --json \
  | python3 -c "import json,sys;[print(r['id'],r['key'],r['homepageId'],r['name']) for r in json.load(sys.stdin)['results'] if 'byte' in r['name'].lower()]"

acli confluence page view --id <homepageId> --include-direct-children --json \
  | python3 -c "import json,sys;[print(c['id'],c['type'],c['title']) for c in json.load(sys.stdin)['directChildren']['results']]"
```

Repeat on the child you want. Children come back as `page`, `folder`, or `database` — only `page` has a body you can read.

## Reading the body

**`page view` without `--json` prints a metadata table only — no content.** To get the body you need both `--json` and `--body-format`:

```bash
acli confluence page view --id <id> --body-format view --json
```

| `--body-format` | Gives you | Use when |
|---|---|---|
| `view` | Rendered HTML — macros already expanded, child-page lists filled in | Reading. Default choice. |
| `storage` | Raw Confluence storage XHTML with `<ac:…>` / `<ri:…>` macros | You need to see how the page is built |

Other useful flags: `--include-direct-children`, `--include-labels`, `--include-version`, `--version <n>` for an older revision.

## Turning it into text

The HTML is dense and full of `local-id` attributes. Pipe it through this to read it:

```bash
acli confluence page view --id <id> --body-format view --json | python3 -c "
import json,sys,re
from html.parser import HTMLParser
class T(HTMLParser):
    def __init__(self):
        super().__init__(); self.out=[]; self.skip=0
    def handle_starttag(self,tag,attrs):
        if tag in ('script','style'): self.skip+=1
        if tag in ('p','div','li','tr','h1','h2','h3','h4','br'): self.out.append('\n')
        if tag=='li': self.out.append('- ')
        if tag in ('td','th'): self.out.append(' | ')
    def handle_endtag(self,tag):
        if tag in ('script','style') and self.skip: self.skip-=1
    def handle_data(self,d):
        if not self.skip: self.out.append(d)
d=json.load(sys.stdin); body=d.get('body') or {}
v=next(iter(body.values()),{}).get('value','')
p=T(); p.feed(v)
print(d.get('title',''))
print(re.sub(r'\n{3,}','\n\n',''.join(p.out)).strip())
"
```

For a long page, write the output to the scratchpad and read it from there rather than scrolling it through the terminal.

Tables survive as `|`-separated lines. Images, attachments, and Jira-issue macros do **not** — they render as an empty gap, so say so instead of assuming the page had nothing there.

## Pitfalls

- Running `page view` without `--json` and reporting "the page is empty" — you only saw the metadata table.
- Looking for a search command, or passing a title to `--id`. Neither exists; get the ID from the URL.
- Trusting `space list --keys`. It is ignored.
- Assuming Jira auth covers Confluence. It doesn't.
- Reading a `folder` or `database` child as a page — they have no body.
- Quoting the whole page back to the user. Answer their question and cite the section.
