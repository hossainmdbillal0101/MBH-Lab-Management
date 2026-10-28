"""Fail on common credentials/private files without printing their contents."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SKIP = {'.wrangler', '.firebase', 'private', '.git', '.dart_tool', 'build', 'node_modules', '.gradle', '.idea', '__pycache__', 'work'}
PRIVATE = {'google-services.json', 'GoogleService-Info.plist', 'firebase_options.dart',
           'key.properties', 'local.properties', 'firebase.local.json', '.env'}
PATTERNS = {
    'OpenAI key': r'sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{30,}',
    'Cloudflare scannable token': r'cfat_[A-Za-z0-9_-]{25,}',
    'literal JWT': r'eyJ[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}',

    'private key': r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
    'Google API key': r'AIza[0-9A-Za-z_-]{35}',
    'GitHub token': r'gh[pousr]_[A-Za-z0-9]{30,}',
    'GitHub fine-grained token': r'github_pat_[A-Za-z0-9_]{40,}',
    'AWS access key': r'AKIA[0-9A-Z]{16}',
    'Firebase private key field': r'"private_key"\s*:',
    'Firebase storage token link': r'firebasestorage\.googleapis\.com[^\s"\x27]*token=',
}

def candidates():
    for p in ROOT.rglob('*'):
        relative = p.relative_to(ROOT)
        if not p.is_file() or any(part in SKIP for part in relative.parts):
            continue
        if p.suffix in {'.log', '.out', '.err', '.pyc', '.class', '.iml'}:
            continue
        # Generated machine configuration is excluded by the packaging script.
        if p.name == 'local.properties' or p.name == 'GeneratedPluginRegistrant.java':
            continue
        yield p, relative

def scan():
    failures = []
    for path, relative in candidates():
        if path.name in PRIVATE or (path.name.startswith('.env.') and not path.name.endswith('.example')) or path.suffix.lower() in {'.jks', '.keystore', '.pem', '.p12', '.pfx', '.pdf', '.docx', '.mp4'}:
            failures.append(f'{relative}: private configuration or unreviewed document')
        try:
            content = path.read_text(encoding='utf-8')
        except (UnicodeError, OSError):
            continue
        for label, pattern in PATTERNS.items():
            if re.search(pattern, content):
                failures.append(f'{relative}: possible {label}')
    return failures

if __name__ == '__main__':
    findings = scan()
    if findings:
        print('\n'.join(findings))
        sys.exit(1)
    print('Publication scan passed: no matched credentials or prohibited public files.')
