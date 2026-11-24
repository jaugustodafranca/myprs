public enum DefaultReviewPrompt {
    public static let template = """
    Review this pull request: {{url}}

    {{repo}}#{{number}} — {{title}}
    - Author: @{{author}}
    - Branch: {{head}} → {{base}}
    - Changes: +{{additions}} −{{deletions}} in {{files}} files
    - CI: {{checks}}

    Use the GitHub CLI to read the description, diff, and existing review comments.
    """
}
