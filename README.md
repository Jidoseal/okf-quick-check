# JidoSeal OKF quick check

Pick a folder, scan it. This GitHub Action grades a folder of markdown files against the [Open Knowledge Format](https://github.com/GoogleCloudPlatform/open-knowledge-format) (OKF) v0.2 as **Bronze, Silver or Gold**, on the runner, using the free JidoSeal Self-Check. It is for teams whose AI tools (Claude Code, Cursor, GitHub Copilot, ChatGPT, Gemini CLI or a local model) work from a folder of docs, and who want a pull request to say when those docs slip.

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
      - uses: Jidoseal/okf-quick-check@v1
        with:
          path: docs          # the folder to scan
          min-tier: bronze    # fail the job below this grade (none, bronze, silver, gold)
```

| Input | Default | Meaning |
|---|---|---|
| `path` | `.` | Folder to scan, relative to the repository root. |
| `min-tier` | `none` | Fail the step if the folder reaches a lower grade. |
| `jidoseal-version` | `0.1.4` | Version of the [`jidoseal`](https://pypi.org/project/jidoseal/) command-line tool to install from PyPI. |

| Output | Meaning |
|---|---|
| `tier` | `gold`, `silver`, `bronze` or `none`: the highest grade that every file in the folder meets. |
| `bronze-coverage`, `silver-coverage`, `gold-coverage` | Percent of files meeting each grade. |

The grade and the coverage are also written to the job summary.

## What it does

1. Creates a Python virtual environment on the runner and installs `jidoseal` from PyPI.
2. Runs `jidoseal --root <path>`. The scan reads the YAML frontmatter of each `*.md` file under the folder.
3. Reads the Bronze, Silver and Gold coverage the tool prints, works out the grade, and fails the step if it is below `min-tier`.

Bronze: every file has an OKF `type`. Silver adds `title`, `description`, `timestamp` and `owner`. Gold adds a lifecycle status, a review policy and the dates of the last and next review. The full definitions are on [jidoseal.com](https://jidoseal.com).

## What it does not do

- JidoSeal states that the scan makes no network connection and sends no file, file name or file content anywhere. The scan engine is proprietary, so that is JidoSeal's own claim, not an independent audit; [how to check it](https://github.com/Jidoseal/jidoseal-mcp#what-leaves-your-machine). (The Action's install step does reach PyPI to fetch the tool.)
- The scan writes a `.jidoseal/` folder (manifest and progress log) inside the scanned folder, in the runner's checkout. Add `.jidoseal/` to your `.gitignore` if you scan locally.
- It does not fix files and it does not issue a certificate. To fix gaps for free, use the [Self-Check](https://jidoseal.com/app/run) or the [MCP server](https://jidoseal.com/mcp) in your AI tool. A certificate is optional, from [jidoseal.com](https://jidoseal.com).
- It checks that frontmatter fields are present, not that the content is correct.

JidoSeal is an independent certifier. It is not affiliated with, sponsored by or endorsed by Google, ISO or any other standards body.

## Test it locally

```bash
test/test.sh                      # installs jidoseal from PyPI into a temp venv and runs five cases
test/test.sh /path/to/jidoseal    # or use a binary you already have
```

## License

The wrapper scripts in this repository (`action.yml`, `scan.sh`, tests, examples) are licensed under Apache-2.0; see [LICENSE](LICENSE). The scan engine the Action installs is proprietary and is not covered by this license.
