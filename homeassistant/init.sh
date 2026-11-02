set -eu
yum install -y tar gzip >/dev/null
if [ ! -f /config/.initialized ]; then
  aws --endpoint-url="$AWS_ENDPOINT" s3 cp "s3://$BUCKET/backup.tgz" /tmp/backup.tgz
  tar -xzf /tmp/backup.tgz -C / config
  test -f /config/configuration.yaml
  touch /config/.initialized
fi
# Runs before HA starts. Preserve YAML and the migrated HTTP store.
python3 - <<'PY'
import json, os, pathlib, re, stat
proxies = ['100.71.109.63/32', '100.71.222.49/32', '100.71.86.199/32']
p = pathlib.Path('/config/configuration.yaml')
s = p.read_text()
match = re.search(r'^  trusted_proxies:\s*$', s, re.M)
if match:
    missing = [v for v in proxies if v not in s]
    if missing:
        s = s[:match.end()] + ''.join('\n    - ' + v for v in missing) + s[match.end():]
        p.write_text(s)
p = pathlib.Path('/config/.storage/http')
if p.exists():
    d = json.loads(p.read_text())
    for key in ['stable', 'pending']:
        config = d.get('data', {}).get(key)
        if config is not None and config.get('use_x_forwarded_for'):
            values = config.setdefault('trusted_proxies', [])
            values.extend(v for v in proxies if v not in values)
    mode = stat.S_IMODE(p.stat().st_mode)
    tmp = p.with_name('http.openbot.tmp')
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, mode)
    with os.fdopen(fd, 'w') as f:
        json.dump(d, f)
    os.replace(tmp, p)
PY
