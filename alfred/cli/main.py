"""Main entry point for Alfred CLI."""

import click

from alfred.cli.health import health


@click.group()
@click.version_option(version="3.0.0")
def cli():
    """Alfred Agent Platform CLI."""
    pass


# Register commands
cli.add_command(health)

if __name__ == "__main__":
    cli()
