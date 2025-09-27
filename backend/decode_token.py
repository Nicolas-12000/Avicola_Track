# decode_token.py
import jwt, json, sys
if len(sys.argv) < 2:
    print("Uso: python decode_token.py <TOKEN>")
    sys.exit(1)
t = sys.argv[1]
payload = jwt.decode(t, options={"verify_signature": False})
print(json.dumps(payload, indent=2, ensure_ascii=False))