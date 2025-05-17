describe('Grouped Alerts UI', () => {
  beforeEach(() => {
    cy.login();
    cy.intercept('GET', '/api/v1/alerts/grouped', { fixture: 'grouped_alerts.json' }).as('getGroups');
    cy.visit('/alerts');
  });

  it('displays grouped alerts accordion', () => {
    cy.wait('@getGroups');
    cy.get('[data-testid="grouped-alerts-accordion"]').should('be.visible');
    cy.get('[data-testid="alert-group"]').should('have.length.greaterThan', 0);
  });

  it('allows selecting multiple groups for merge', () => {
    cy.get('[data-testid="group-checkbox-1"]').check();
    cy.get('[data-testid="group-checkbox-2"]').check();
    cy.get('[data-testid="merge-button"]').should('be.enabled');
    cy.get('[data-testid="merge-button"]').should('contain', 'Merge Selected (2)');
  });

  it('shows merge confirmation dialog', () => {
    cy.get('[data-testid="group-checkbox-1"]').check();
    cy.get('[data-testid="group-checkbox-2"]').check();
    cy.get('[data-testid="merge-button"]').click();
    
    cy.get('[data-testid="merge-dialog"]').should('be.visible');
    cy.get('[data-testid="merge-dialog"]').should('contain', 'Confirm Merge');
  });

  it('performs merge operation successfully', () => {
    cy.intercept('POST', '/api/v1/alerts/groups/merge', { status: 'success' }).as('mergeGroups');
    
    cy.get('[data-testid="group-checkbox-1"]').check();
    cy.get('[data-testid="group-checkbox-2"]').check();
    cy.get('[data-testid="merge-button"]').click();
    cy.get('[data-testid="confirm-merge"]').click();
    
    cy.wait('@mergeGroups');
    cy.get('.toast-success').should('contain', 'Groups merged successfully');
  });

  it('performs unmerge operation', () => {
    cy.intercept('POST', '/api/v1/alerts/groups/*/unmerge', { status: 'success' }).as('unmergeGroup');
    
    cy.get('[data-testid="unmerge-button-1"]').click();
    
    cy.wait('@unmergeGroup');
    cy.get('.toast-success').should('contain', 'Group unmerged successfully');
  });

  it('disables merge button with less than 2 selections', () => {
    cy.get('[data-testid="merge-button"]').should('be.disabled');
    
    cy.get('[data-testid="group-checkbox-1"]').check();
    cy.get('[data-testid="merge-button"]').should('be.disabled');
    
    cy.get('[data-testid="group-checkbox-2"]').check();
    cy.get('[data-testid="merge-button"]').should('be.enabled');
  });

  it('updates selection count in real-time', () => {
    cy.get('[data-testid="merge-button"]').should('contain', 'Merge Selected (0)');
    
    cy.get('[data-testid="group-checkbox-1"]').check();
    cy.get('[data-testid="merge-button"]').should('contain', 'Merge Selected (1)');
    
    cy.get('[data-testid="group-checkbox-2"]').check();
    cy.get('[data-testid="merge-button"]').should('contain', 'Merge Selected (2)');
    
    cy.get('[data-testid="group-checkbox-1"]').uncheck();
    cy.get('[data-testid="merge-button"]').should('contain', 'Merge Selected (1)');
  });

  it('handles merge operation error gracefully', () => {
    cy.intercept('POST', '/api/v1/alerts/groups/merge', {
      statusCode: 500,
      body: { error: 'Merge failed' }
    }).as('mergeError');
    
    cy.get('[data-testid="group-checkbox-1"]').check();
    cy.get('[data-testid="group-checkbox-2"]').check();
    cy.get('[data-testid="merge-button"]').click();
    cy.get('[data-testid="confirm-merge"]').click();
    
    cy.wait('@mergeError');
    cy.get('.toast-destructive').should('contain', 'Merge failed');
  });
});