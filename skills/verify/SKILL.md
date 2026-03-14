---
name: verify
description: Computationally verify a mathematical identity, construction, or cryptographic property using Python.
argument-hint: "<expression, identity, or property to verify>"
---

The user wants computational verification of a mathematical or cryptographic claim. Follow this process:

1. **Parse.** Identify exactly what needs to be verified — an identity, a group law, a polynomial relation, a security property on small parameters, etc.
2. **Plan.** Decide the right tool:
   - Symbolic: `sympy` for algebraic identities, polynomial manipulations
   - Finite fields / number theory: `galois`, `gmpy2`, or `sympy.ntheory`
   - Elliptic curves: `sympy` or direct implementation over `galois`
   - Brute force on small instances: plain Python loops
3. **Implement.** Write a clean Python script. 4. **Run.** Execute and report results clearly.
5. **Interpret.** Explain what the computation confirms (or refutes), and note any limitations (e.g., "verified for all primes < 1000 but this is not a proof").

Claim to verify: $ARGUMENTS
