"""Add alert group table

Revision ID: 20250520_001
Revises:
Create Date: 2025-05-20 00:00:00.000000

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "20250520_001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    """Create alert_groups table."""
    op.create_table(
        "alert_groups",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("group_key", sa.String(length=255), nullable=False),
        sa.Column("first_seen", sa.DateTime(), nullable=False),
        sa.Column("last_seen", sa.DateTime(), nullable=False),
        sa.Column("alert_count", sa.Integer(), nullable=True),
        sa.Column("parent_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("severity_score", sa.Float(), nullable=True),
        sa.ForeignKeyConstraint(
            ["parent_id"],
            ["alert_groups.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_alert_groups_group_key"), "alert_groups", ["group_key"], unique=False)

    # Add group_id to existing alerts table
    op.add_column("alerts", sa.Column("group_id", postgresql.UUID(as_uuid=True), nullable=True))
    op.create_foreign_key(None, "alerts", "alert_groups", ["group_id"], ["id"])


def downgrade():
    """Drop alert_groups table and related columns."""
    op.drop_constraint(None, "alerts", type_="foreignkey")
    op.drop_column("alerts", "group_id")
    op.drop_index(op.f("ix_alert_groups_group_key"), table_name="alert_groups")
    op.drop_table("alert_groups")
