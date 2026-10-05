#!/usr/bin/env python3
"""
Rigenera il contenuto del manuale nella pagina web del sito (manuale.html) dai capitoli Markdown.

Uso:  ./build-site.py <percorso/manuale.html> [versione]

Sostituisce il corpo dei capitoli (div.manual-content), l'indice laterale, il badge di versione, il
link al PDF e la versione nel piede della pagina. Il resto della pagina non si tocca.
Richiede pandoc. La versione di default e' quella di vulnerability-manager-frontend/package.json.
"""
import glob
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def package_version() -> str:
    pkg = os.path.join(HERE, '..', '..', 'vulnerability-manager-frontend', 'package.json')
    with open(pkg, encoding='utf-8') as f:
        return re.search(r'^  "version": "([^"]+)"', f.read(), re.M).group(1)


def chapters_html() -> list[tuple[str, str, str]]:
    """(id, titolo, html) per capitolo, da UN solo pandoc cosi' gli id del codice colorato restano unici."""
    files = sorted(glob.glob(os.path.join(HERE, '[0-9][0-9]-*.md')))
    html = subprocess.run(
        ['pandoc', '--shift-heading-level-by=1', '-f', 'markdown', '-t', 'html5', '--wrap=none', *files],
        capture_output=True, text=True, check=True,
    ).stdout
    parts = re.split(r'(?=<h2 id=")', html)
    result = []
    for part in parts:
        m = re.match(r'<h2 id="([^"]+)">(.*?)</h2>', part, re.S)
        if not m:
            continue
        body = part.replace(m.group(0), f'<h2>{m.group(2)}</h2>', 1).strip()
        result.append((m.group(1), re.sub(r'<[^>]+>', '', m.group(2)), body))
    return result


def main() -> None:
    target = sys.argv[1]
    version = sys.argv[2] if len(sys.argv) > 2 else package_version()
    with open(target, encoding='utf-8') as f:
        page = f.read()

    chapters = chapters_html()
    sections = '\n'.join(
        f'      <section class="manual-chapter" id="{cid}">\n{body}\n\n      </section>' for cid, _, body in chapters
    )
    start_tag = '<div class="manual-content">'
    start = page.index(start_tag) + len(start_tag)
    end = page.index('</div>\n    </section>\n\n  </main>')
    page = page[:start] + '\n' + sections + '\n      ' + page[end:]

    toc = '\n'.join(f'          <li><a href="#{cid}">{title}</a></li>' for cid, title, _ in chapters)
    page = re.sub(r'(<nav class="manual-toc"[^>]*>\s*<h5>Indice</h5>\s*<ul>\n).*?(\s*</ul>)', lambda m: m.group(1) + toc + m.group(2), page, count=1, flags=re.S)

    page = re.sub(r'(badge-version"><span class="dot"></span> v)[0-9][^<]*', r'\g<1>' + version, page, count=1)
    page = re.sub(r'SentinelCore-Manuale-Utente-[0-9][^"]*\.pdf', f'SentinelCore-Manuale-Utente-{version}.pdf', page)
    page = re.sub(r'(sentinelcore v)[0-9][0-9.]*', r'\g<1>' + version, page, count=1)

    with open(target, 'w', encoding='utf-8') as f:
        f.write(page)
    print(f'{target}: {len(chapters)} capitoli, versione {version}')


if __name__ == '__main__':
    main()
