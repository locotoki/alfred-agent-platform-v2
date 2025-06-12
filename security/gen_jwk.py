import base64
import json
import sys

import rsa

key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
pub = key.public_key().public_numbers()
b64 = (
    lambda n: base64.urlsafe_b64encode(n.to_bytes((n.bit_length() + 7) // 8, "big"))
    .rstrip(b"=")
    .decode()
)
new = {
    "kty": "RSA",
    "use": "sig",
    "alg": "RS256",
    "kid": f"k{int(sys.argv[1])}",
    "n": b64(pub.n),
    "e": b64(pub.e),
}
jwks = json.load(open("security/jwks.json"))
jwks["keys"].append(new)
json.dump(jwks, open("security/jwks.json", "w"), indent=2)
