import os, sys, re
from github import Github

RULES = {
    "require_ids": {
        "pattern": r"prd-id:.*\bPRD-[0-9]{4}-[0-9]+.*\btask-id:.*\b[0-9]+",
        "message": "PR description must contain both `prd-id:` and `task-id:`."
    }
}

def main():
    pr_number = os.environ.get("PR_NUMBER")
    repo_full = os.environ["GITHUB_REPOSITORY"]
    token = os.environ["GITHUB_TOKEN"]
    g = Github(token)
    repo = g.get_repo(repo_full)
    pr = repo.get_pull(int(pr_number))
    body = pr.body or ""
    errors = []
    rule = RULES["require_ids"]
    if not re.search(rule["pattern"], body, re.IGNORECASE | re.DOTALL):
        errors.append(rule["message"])
    if errors:
        pr.create_issue_comment("\n".join(errors))
        pr.create_review(body="Reviewer agent failed rules.", event="REQUEST_CHANGES")
        sys.exit(1)
    else:
        pr.create_review(body="Reviewer agent passed all rules.", event="APPROVE")
        sys.exit(0)

if __name__ == "__main__":
    main()