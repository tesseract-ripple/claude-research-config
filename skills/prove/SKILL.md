---
name: prove
description: Construct or verify a mathematical proof. Provide a claim/theorem and optionally a proof technique.
argument-hint: "<claim to prove or verify>"
---

The user wants a rigorous mathematical proof. Follow this process:

1. **Parse the claim.** Restate it precisely with all quantifiers, domains, and assumptions explicit.
2. **Identify the technique.** Choose the most natural proof method (direct, contradiction, induction, reduction, etc.). If the user specified one, use it.
3. **Outline first.** Present a 3-5 step proof skeleton before writing the full proof.
4. **Execute.** Write the complete proof with every step justified.
5. **Verify computationally.** If feasible, use Python (sympy/galois/gmpy2 ) to check key steps, boundary cases, or small instances.
6. **Assess.** Flag any steps that rely on non-obvious lemmas, and note if the proof generalizes.

If the user provides an existing proof to verify, be adversarial: actively hunt for gaps, unjustified steps, and edge cases.

Claim or context: $ARGUMENTS
