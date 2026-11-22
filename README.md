# JidoSeal OKF quick check

Pick a folder, scan it. This GitHub Action grades a folder of markdown files against the [Open Knowledge Format](https://github.com/GoogleCloudPlatform/open-knowledge-format) (OKF) v0.2 as **OKF Certified, Bronze, Silver or Gold**, against the [OKF Folder Criteria v1.0.0](https://github.com/Jidoseal/okf-folder-criteria/blob/v1.0.0/CRITERIA.md), on the runner, using the free JidoSeal Self-Check. It is for teams whose AI tools (Claude Code, Cursor, GitHub Copilot, ChatGPT, Gemini CLI or a local model) work from a folder of docs, and who want a pull request to say when those docs slip.

The scan is free. A JidoSeal certificate is optional and is the only paid thing; this Action never buys one.

## Use it

```yaml
name: OKF quick check
on: [pull_request]
jobs:
  okf:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Jidoseal/okf-quick-check@v2
        with:
          path: docs          # the folder to scan
          min-tier: bronze    # fail the job below this grade (none, okf-certified, bronze, silver, gold)
```

| Input | Default | Meaning |
|---|---|---|
| `path` | `.` | Folder to scan, relative to the repository root. |
| `min-tier` | `none` | Fail the step if the folder reaches a lower grade. |
| `jidoseal-version` | `0.2.0` | Version of the [`jidoseal`](https://pypi.org/project/jidoseal/) command-line tool to install from PyPI. Must be 0.2.0 or later. |

| Output | Meaning |
|---|---|
| `tier` | `gold`, `silver`, `bronze`, `okf-certified` or `none`: the folder grade, which is the lowest grade of any file in scope. |
| `criteria-version` | Version of the OKF Folder Criteria the grade uses (`1.0.0`). |
| `score` | Mean of the four coverage figures, 0 to 100. |
| `okf-certified-coverage`, `bronze-coverage`, `silver-coverage`, `gold-coverage` | Percent of files meeting each grade. |

The grade and the coverage are also written to the job summary.

## What it does

1. Creates a Python virtual environment on the runner and installs `jidoseal` from PyPI.
2. Runs `jidoseal --root <path> --criteria 1.0.0`. The scan reads the YAML frontmatter of each `*.md` file under the folder.
3. Reads the grade, score and coverage from the manifest the scan writes, and fails the step if the grade is below `min-tier`.

The grades, per OKF Folder Criteria v1.0.0:

- **OKF Certified**: the folder passes the three conformance rules of OKF v0.2 section 11 (rules O1 to O3): each file has frontmatter that parses as YAML, each file has a `type`, and any `index.md` and `log.md` follow their OKF sections.
- **Bronze** adds `title`, `description`, a date such as `timestamp`, and an accountable `owner`.
- **Silver** adds a lifecycle `status`, a review policy, and the dates of the last and next review.
- **Gold** adds AI-provenance fields: `ai_involvement`, `sources`, `generated` and `verified` where AI was involved, and `license`.

The full definitions are in [CRITERIA.md](https://github.com/Jidoseal/okf-folder-criteria/blob/v1.0.0/CRITERIA.md).

## What it does not do

- JidoSeal states that the scan makes no network connection and sends no file, file name or file content anywhere. The scan engine is proprietary, so that is JidoSeal's own claim, not an independent audit; [how to check it](https://github.com/Jidoseal/jidoseal-mcp#what-leaves-your-machine). (The Action's install step does reach PyPI to fetch the tool.)
- The scan writes a `.jidoseal/` folder (manifest and progress log) inside the scanned folder, in the runner's checkout. Add `.jidoseal/` to your `.gitignore` if you scan locally.
- It does not fix files and it does not issue a certificate. To fix gaps for free, use the [Self-Check](https://jidoseal.com/app/run) or the [MCP server](https://jidoseal.com/mcp) in your AI tool. A certificate is optional, from [jidoseal.com](https://jidoseal.com).
- It checks that frontmatter fields are present and well formed, not that the content is correct.

JidoSeal is an independent certifier. It is not affiliated with, sponsored by or endorsed by Google, ISO or any other standards body.

## Upgrading from v1

The `v1` tag and the v1.0.x releases are unchanged. They grade with the older names and use `jidoseal` 0.1.4 or 0.1.5.

The bars kept their field requirements and changed names. Every v2 grade also requires the three OKF section 11 rules, so a folder can grade lower on v2 than on v1.

| v1 name | v2 name (criteria v1.0.0) |
|---|---|
| Silver | Bronze |
| Gold | Silver |

v2 adds OKF Certified below Bronze and a new Gold above Silver. If you used `min-tier: gold` on v1, use `min-tier: silver` on v2 to keep the same bar.

> **Warning:** do not run v1 with `jidoseal-version` 0.2.0 or later. v1 reads the printed coverage lines, and 0.2.0 prints the new Bronze line where v1 expects the old one, so v1 reports the wrong grade. Keep v1 on 0.1.5, or move to v2.

## Test it locally

```bash
test/test.sh                      # installs jidoseal from PyPI into a temp venv and runs six cases
test/test.sh /path/to/jidoseal    # or use a binary you already have
```

## License

The wrapper scripts in this repository (`action.yml`, `scan.sh`, tests, examples) are licensed under Apache-2.0; see [LICENSE](LICENSE). The scan engine the Action installs is proprietary and is not covered by this license.
