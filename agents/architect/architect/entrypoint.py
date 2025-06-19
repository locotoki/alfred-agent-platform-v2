from common.prompt_builder import build_prompt
import sys

def main():
    """Architect agent entrypoint with prompt_builder integration."""
    # Example usage
    system_snippets = ["System context snippet 1", "System context snippet 2"]
    user_query = "Generate a PRD for the new feature"
    
    prompt = build_prompt(system_snippets, user_query)
    
    print(f"Generated prompt with {len(prompt)} characters")
    print("Prompt preview:", prompt[:200] + "..." if len(prompt) > 200 else prompt)

if __name__ == "__main__":
    main()