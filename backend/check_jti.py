# check_jti.py
# Usage: python check_jti.py <jti>
import sys
if len(sys.argv) < 2:
    print("Usage: python check_jti.py <jti>")
    sys.exit(1)

jti = sys.argv[1]

# We'll import Django settings and use ORM
import django
import os
from pathlib import Path
BASE_DIR = Path(__file__).resolve().parent
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'avicolatrack.settings.development')
django.setup()

from rest_framework_simplejwt.token_blacklist.models import OutstandingToken, BlacklistedToken

outs = OutstandingToken.objects.filter(jti=jti)
print("OutstandingToken count:", outs.count())
for o in outs:
    # Different versions of simplejwt use different field names (expires_at or expires)
    expires = getattr(o, 'expires_at', getattr(o, 'expires', None))
    print(f"user: {o.user} | expires: {expires} | jti: {o.jti}")

bl = BlacklistedToken.objects.filter(token__jti=jti)
print("BlacklistedToken count:", bl.count())
for b in bl:
    print(f"blacklisted token jti: {b.token.jti} | user: {b.token.user}")
