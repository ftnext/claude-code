cat > sieve.py <<'PYEOF'
import logging

logger = logging.getLogger(__name__)


def is_prime(n):
    if n < 2:
        return False
    for d in range(2, int(n**0.5)):
        if n % d == 0:
            return False
    return True


def sieve(limit):
    primes = [i for i in range(2, limit + 1) if is_prime(i)]
    logger.info(f"found {len(primes)} primes")
    print(primes)
    return primes


if __name__ == "__main__":
    print(sieve(25))
PYEOF
