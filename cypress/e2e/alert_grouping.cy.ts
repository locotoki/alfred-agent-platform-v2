describe('Alert Grouping Feature', () => {
  beforeEach(() => {
    cy.visit('/alerts');
  });

  context('When feature flag is enabled', () => {
    beforeEach(() => {
      cy.window().then((win) => {
        win.featureFlags = { ALERT_GROUPING_ENABLED: true };
      });
    });

    it('should display grouped alerts component', () => {
      cy.get('[data-testid="grouped-alerts"]').should('exist');
      cy.contains('Grouped Alerts').should('be.visible');
    });

    it('should show alert groups with count badges', () => {
      // Mock API response
      cy.intercept('POST', '/api/v1/alerts/grouped', {
        statusCode: 200,
        body: {
          groups: [
            {
              id: 'group-1',
              key: 'api-gateway:HighCPU:warning',
              count: 5,
              first_seen: new Date().toISOString(),
              last_seen: new Date().toISOString(),
              severity: 'warning'
            },
            {
              id: 'group-2',
              key: 'database:HighMemory:critical',
              count: 3,
              first_seen: new Date().toISOString(),
              last_seen: new Date().toISOString(),
              severity: 'critical'
            }
          ]
        }
      }).as('getGroupedAlerts');

      cy.wait('@getGroupedAlerts');

      // Check badges
      cy.contains('5 alerts').should('be.visible');
      cy.contains('3 alerts').should('be.visible');

      // Check severity indicators
      cy.get('[data-severity="warning"]').should('have.length', 1);
      cy.get('[data-severity="critical"]').should('have.length', 1);
    });

    it('should expand/collapse accordion items', () => {
      // Click on first accordion item
      cy.get('[data-testid="accordion-trigger"]').first().click();
      
      // Check content is visible
      cy.contains('First seen:').should('be.visible');
      cy.contains('Alert count:').should('be.visible');
      
      // Click again to collapse
      cy.get('[data-testid="accordion-trigger"]').first().click();
      
      // Check content is hidden
      cy.contains('First seen:').should('not.be.visible');
    });

    it('should show empty state when no alerts', () => {
      cy.intercept('POST', '/api/v1/alerts/grouped', {
        statusCode: 200,
        body: { groups: [] }
      }).as('getEmptyAlerts');

      cy.wait('@getEmptyAlerts');

      cy.contains('No grouped alerts to display').should('be.visible');
    });
  });

  context('When feature flag is disabled', () => {
    beforeEach(() => {
      cy.window().then((win) => {
        win.featureFlags = { ALERT_GROUPING_ENABLED: false };
      });
    });

    it('should not display grouped alerts component', () => {
      cy.get('[data-testid="grouped-alerts"]').should('not.exist');
      cy.contains('Grouped Alerts').should('not.exist');
    });
  });
});