enum DefaultReviewPrompt {
    static let template = """
    Review this pull request: {{url}}
    "{{title}}" by @{{author}} — {{repo}}#{{number}}
    Branch: {{head}} → {{base}} · +{{additions}} −{{deletions}} in {{files}} files · CI: {{checks}}

    Use the GitHub CLI (`gh pr view {{number}} -R {{repo}}`, `gh pr diff {{number}} -R {{repo}}`)
    to read the description, the diff and the existing review comments.

    1. Summary — what changed and why, in plain language (5 bullets max).
    2. How to test — step-by-step manual test plan, including edge cases and anything
       that needs specific data, flags or environments.
    3. Code review, from these perspectives:
       - Correctness and edge cases (nulls, errors, concurrency, data migrations)
       - Security (auth, input validation, secrets, injection)
       - Performance (N+1, unnecessary work, memory)
       - Readability and naming; simpler alternatives
       - Consistency with this repo's patterns — look at recent merged PRs and their
         review comments (`gh pr list -R {{repo}} --state merged -L 10`) and flag
         anything reviewers usually ask to change
       - Tests: what's covered, what's missing
    4. Findings — list each issue with file:line, severity (blocking / should fix / nit)
       and a concrete suggestion. Only report issues you verified in the code.
    5. Verdict — approve, approve with comments, or request changes, in one sentence.
    """
}
