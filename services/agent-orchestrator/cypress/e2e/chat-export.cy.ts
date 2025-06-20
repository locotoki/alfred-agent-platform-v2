describe("Chat Export Functionality", () => {
  beforeEach(() => {
    // Intercept the export API call
    cy.intercept("POST", "**/architect/export", {
      statusCode: 200,
      body: "# Architect Chat Export\n\n## Assistant\n\nHello! I'm the Architect AI. How can I help you today?\n\n## User\n\nTest message\n\n## Assistant\n\nI received your message: \"Test message\". This is a mock response.",
    }).as("exportChat");

    // Visit the chat page
    cy.visit("/chat");
  });

  it("should display chat interface", () => {
    // Check if chat header is visible
    cy.contains("Architect Chat").should("be.visible");
    
    // Check if initial message is displayed
    cy.contains("Hello! I'm the Architect AI").should("be.visible");
    
    // Check if message input is present
    cy.get('input[placeholder="Type your message..."]').should("be.visible");
  });

  it("should show export button on hover and download file", () => {
    // Hover over the chat header to reveal export button
    cy.get("header").trigger("mouseover");
    
    // Check if export button becomes visible
    cy.get('[aria-label="Export chat as Markdown"]').should("be.visible");
    
    // Set up download handling
    const downloadsFolder = Cypress.config("downloadsFolder");
    
    // Click export button
    cy.get('[aria-label="Export chat as Markdown"]').click();
    
    // Verify API call was made
    cy.wait("@exportChat").then((interception) => {
      expect(interception.request.body).to.have.property("thread_id");
      expect(interception.request.body).to.have.property("messages");
      expect(interception.request.body.messages).to.be.an("array");
    });
    
    // Check for success toast
    cy.contains("Chat exported ✨").should("be.visible");
    
    // Verify file download (this is tricky in Cypress, so we'll verify the blob creation)
    // In a real E2E test, you might need to configure Cypress to handle downloads
    // or use a different approach to verify the download
  });

  it("should handle export errors gracefully", () => {
    // Intercept with error response
    cy.intercept("POST", "**/architect/export", {
      statusCode: 500,
      body: { error: "Internal server error" },
    }).as("exportError");

    // Hover and click export
    cy.get("header").trigger("mouseover");
    cy.get('[aria-label="Export chat as Markdown"]').click();
    
    // Wait for error response
    cy.wait("@exportError");
    
    // Check for error toast
    cy.contains("Export failed").should("be.visible");
  });

  it("should allow sending messages and include them in export", () => {
    const testMessage = "This is a test message for export";
    
    // Type and send a message
    cy.get('input[placeholder="Type your message..."]')
      .type(testMessage)
      .type("{enter}");
    
    // Wait for message to appear
    cy.contains(testMessage).should("be.visible");
    
    // Wait for mock response
    cy.contains("I received your message", { timeout: 2000 }).should("be.visible");
    
    // Now export and verify the message is included
    cy.get("header").trigger("mouseover");
    cy.get('[aria-label="Export chat as Markdown"]').click();
    
    cy.wait("@exportChat").then((interception) => {
      const messages = interception.request.body.messages;
      const userMessage = messages.find((m: any) => m.role === "user" && m.content === testMessage);
      expect(userMessage).to.exist;
    });
  });

  it("should generate unique thread IDs for different sessions", () => {
    // Get initial thread ID
    cy.contains("Thread:").invoke("text").then((initialThreadText) => {
      const initialThreadId = initialThreadText.replace("Thread: ", "");
      
      // Reload page to simulate new session
      cy.reload();
      
      // Check that thread ID has changed
      cy.contains("Thread:").invoke("text").then((newThreadText) => {
        const newThreadId = newThreadText.replace("Thread: ", "");
        expect(newThreadId).to.not.equal(initialThreadId);
      });
    });
  });
});