import time
import uuid

import jwt

from alfred_sdk.auth.verify import _get_jwks, verify


def test_verify_roundtrip():
    jwk = _get_jwks()["k1"]
    key = jwt.algorithms.RSAAlgorithm.from_jwk(jwk)
    token = jwt.encode(
        {"sub": str(uuid.uuid4()), "tenant": "demo", "scope": "test", "exp": time.time() + 60},
        key,
        algorithm="RS256",
        headers={"kid": "k1"},
    )
    claims = verify(token)
    assert claims["tenant"] == "demo"
