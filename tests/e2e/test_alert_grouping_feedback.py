"""
E2E tests for alert grouping user feedback flows.
"""

import pytest
from playwright.sync_api import Page
from tests.e2e.fixtures import authenticated_page
import time


def test_user_can_merge_similar_alerts(authenticated_page: Page):
    """Test that users can manually merge similar alert groups."""
    # Navigate to alerts page
    authenticated_page.goto("/alerts")
    
    # Wait for grouped alerts to load
    authenticated_page.wait_for_selector("[data-testid='grouped-alerts']")
    
    # Select two alert groups
    authenticated_page.check("[data-testid='group-checkbox-1']")
    authenticated_page.check("[data-testid='group-checkbox-2']")
    
    # Click merge button
    authenticated_page.click("[data-testid='merge-button']")
    
    # Confirm merge in dialog
    authenticated_page.click("[data-testid='confirm-merge']")
    
    # Verify merge completed
    success_toast = authenticated_page.locator(".toast-success")
    assert success_toast.is_visible()
    assert "Groups merged successfully" in success_toast.text_content()
    
    # Verify group count decreased
    groups = authenticated_page.locator("[data-testid^='alert-group-']")
    assert groups.count() == 1


def test_user_can_unmerge_alerts(authenticated_page: Page):
    """Test that users can unmerge previously grouped alerts."""
    # Navigate to alerts page with merged group
    authenticated_page.goto("/alerts?groupId=merged-123")
    
    # Click unmerge button
    authenticated_page.click("[data-testid='unmerge-button']")
    
    # Verify unmerge completed
    success_toast = authenticated_page.locator(".toast-success")
    assert success_toast.is_visible()
    assert "Group unmerged successfully" in success_toast.text_content()
    
    # Verify individual alerts are shown
    alerts = authenticated_page.locator("[data-testid^='individual-alert-']")
    assert alerts.count() > 1


def test_merge_performance_under_2_seconds(authenticated_page: Page):
    """Test that merge operation completes within 2 seconds."""
    authenticated_page.goto("/alerts")
    authenticated_page.wait_for_selector("[data-testid='grouped-alerts']")
    
    # Select groups
    authenticated_page.check("[data-testid='group-checkbox-1']")
    authenticated_page.check("[data-testid='group-checkbox-2']")
    
    # Time the merge operation
    start_time = time.time()
    authenticated_page.click("[data-testid='merge-button']")
    authenticated_page.click("[data-testid='confirm-merge']")
    
    # Wait for completion
    authenticated_page.wait_for_selector(".toast-success")
    end_time = time.time()
    
    # Verify performance
    duration = end_time - start_time
    assert duration < 2.0, f"Merge took {duration:.2f}s, expected < 2s"


def test_grouping_respects_feature_flag(authenticated_page: Page):
    """Test that grouping is only shown when feature flag is enabled."""
    # First, test with flag disabled
    authenticated_page.set_extra_http_headers({"X-Feature-Flag": "off"})
    authenticated_page.goto("/alerts")
    
    # Should not see grouped view
    assert not authenticated_page.locator("[data-testid='grouped-alerts']").is_visible()
    
    # Now test with flag enabled
    authenticated_page.set_extra_http_headers({"X-Feature-Flag": "on"})
    authenticated_page.reload()
    
    # Should see grouped view
    assert authenticated_page.locator("[data-testid='grouped-alerts']").is_visible()


@pytest.mark.parametrize("similarity_threshold", [0.5, 0.7, 0.9])
def test_grouping_similarity_settings(authenticated_page: Page, similarity_threshold: float):
    """Test different similarity threshold settings."""
    authenticated_page.goto(f"/alerts?similarity={similarity_threshold}")
    authenticated_page.wait_for_selector("[data-testid='grouped-alerts']")
    
    # Verify group count changes with threshold
    groups = authenticated_page.locator("[data-testid^='alert-group-']")
    group_count = groups.count()
    
    # Higher threshold should result in more groups (less grouping)
    if similarity_threshold == 0.9:
        assert group_count > 5
    elif similarity_threshold == 0.5:
        assert group_count < 3