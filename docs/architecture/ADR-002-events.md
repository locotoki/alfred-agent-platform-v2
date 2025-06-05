# ADR-002: Event Contract Catalog

**Decision:**  
* CloudEvents v1.0 JSON envelope  
* Protobuf 3 payloads under `data`  
* `ce-type` = `<agent>.<event>.v<major>` (semver)  
* Topic = `<tenant>.<agent>.<event>`  
* Schemas live in `/schemas` and are CI-checked for backward compatibility.