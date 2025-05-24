"""HubSpot Mock Service for local development."""

import uuid
from datetime import datetime
from typing import Dict, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="HubSpot Mock Service", version="1.0.0")

# In-memory storage
contacts_db: Dict[str, dict] = {}
companies_db: Dict[str, dict] = {}
deals_db: Dict[str, dict] = {}


class Contact(BaseModel):
    """Contact model for HubSpot CRM."""

    email: str
    firstname: Optional[str] = None
    lastname: Optional[str] = None
    properties: Optional[Dict] = None


class Company(BaseModel):
    """Company model for HubSpot CRM."""

    name: str
    domain: Optional[str] = None
    properties: Optional[Dict] = None


class Deal(BaseModel):
    """Deal model for HubSpot CRM."""

    dealname: str
    amount: Optional[float] = None
    dealstage: Optional[str] = "appointmentscheduled"
    properties: Optional[Dict] = None


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "hubspot-mock"}


@app.post("/crm/v3/objects/contacts")
async def create_contact(contact: Contact):
    """Create a new contact."""
    contact_id = str(uuid.uuid4())
    contact_data = {
        "id": contact_id,
        "properties": {
            "email": contact.email,
            "firstname": contact.firstname,
            "lastname": contact.lastname,
            "createdate": datetime.utcnow().isoformat(),
            **(contact.properties or {}),
        },
    }
    contacts_db[contact_id] = contact_data
    return contact_data


@app.get("/crm/v3/objects/contacts/{contact_id}")
async def get_contact(contact_id: str):
    """Get a contact by ID."""
    if contact_id not in contacts_db:
        raise HTTPException(status_code=404, detail="Contact not found")
    return contacts_db[contact_id]


@app.post("/crm/v3/objects/companies")
async def create_company(company: Company):
    """Create a new company."""
    company_id = str(uuid.uuid4())
    company_data = {
        "id": company_id,
        "properties": {
            "name": company.name,
            "domain": company.domain,
            "createdate": datetime.utcnow().isoformat(),
            **(company.properties or {}),
        },
    }
    companies_db[company_id] = company_data
    return company_data


@app.post("/crm/v3/objects/deals")
async def create_deal(deal: Deal):
    """Create a new deal."""
    deal_id = str(uuid.uuid4())
    deal_data = {
        "id": deal_id,
        "properties": {
            "dealname": deal.dealname,
            "amount": deal.amount,
            "dealstage": deal.dealstage,
            "createdate": datetime.utcnow().isoformat(),
            **(deal.properties or {}),
        },
    }
    deals_db[deal_id] = deal_data
    return deal_data


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "HubSpot Mock Service",
        "endpoints": {
            "health": "/health",
            "contacts": "/crm/v3/objects/contacts",
            "companies": "/crm/v3/objects/companies",
            "deals": "/crm/v3/objects/deals",
        },
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8095)