"""Core entrypoint module."""

from alfred.protocols import Status


def main():
    """Run main entrypoint using new status."""
    status = Status.ACTIVE
    print(f"Status: {status}")


if __name__ == "__main__":
    main()  # type: ignore
