"""Load test for alert grouping API endpoint."""

import time
from locust import HttpUser, task, between
from locust.exception import StopUser


class AlertGroupingUser(HttpUser):
    """User simulating alert grouping API calls."""
    
    wait_time = between(1, 3)  # Wait 1-3 seconds between requests
    
    def on_start(self):
        """Set up test data on start."""
        self.headers = {
            "Content-Type": "application/json",
            "X-Feature-Flag": "on"
        }
        
        # Track response times for P95 calculation
        self.response_times = []
    
    @task
    def get_grouped_alerts(self):
        """Test the grouped alerts endpoint."""
        payload = {
            "strategy": "jaccard",
            "time_window": 900  # 15 minutes
        }
        
        start_time = time.time()
        
        with self.client.post(
            "/api/v1/alerts/grouped",
            json=payload,
            headers=self.headers,
            catch_response=True
        ) as response:
            response_time = (time.time() - start_time) * 1000  # Convert to ms
            self.response_times.append(response_time)
            
            # Check response
            if response.status_code != 200:
                response.failure(f"Got status code {response.status_code}")
            else:
                # Validate response structure
                try:
                    data = response.json()
                    if "groups" not in data:
                        response.failure("Response missing 'groups' field")
                    else:
                        response.success()
                except Exception as e:
                    response.failure(f"Failed to parse JSON: {e}")
            
            # Fail if P95 > 150ms (check every 100 requests)
            if len(self.response_times) >= 100:
                sorted_times = sorted(self.response_times)
                p95_index = int(len(sorted_times) * 0.95)
                p95_time = sorted_times[p95_index]
                
                if p95_time > 150:
                    print(f"P95 latency {p95_time:.1f}ms exceeds 150ms limit!")
                    response.failure(f"P95 latency {p95_time:.1f}ms > 150ms")
                    raise StopUser("P95 latency exceeded")
                
                # Reset for next batch
                self.response_times = self.response_times[-50:]
    
    @task(2)
    def get_grouped_alerts_with_custom_window(self):
        """Test with custom time window."""
        payload = {
            "strategy": "jaccard",
            "time_window": 1800  # 30 minutes
        }
        
        with self.client.post(
            "/api/v1/alerts/grouped",
            json=payload,
            headers=self.headers,
            catch_response=True
        ) as response:
            if response.status_code != 200:
                response.failure(f"Got status code {response.status_code}")


# Configuration for the test
# Run with: locust -f load/alert_group.py --headless -u 50 -r 10 -t 2m
# This will:
# - Run for 2 minutes (-t 2m)
# - Spawn 50 users (-u 50)
# - Ramp up at 10 users/second (-r 10)
# - Run without UI (--headless)