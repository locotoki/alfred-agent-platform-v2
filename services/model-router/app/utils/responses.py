from typing import Any, Dict, List, Optional, Union
from fastapi import HTTPException, status
from fastapi.responses import JSONResponse
import logging

logger = logging.getLogger(__name__)

class ErrorCode:
    """Error codes for API responses"""
    INVALID_REQUEST = "INVALID_REQUEST"
    MODEL_NOT_FOUND = "MODEL_NOT_FOUND"
    MODEL_NOT_AVAILABLE = "MODEL_NOT_AVAILABLE"
    ROUTING_FAILED = "ROUTING_FAILED"
    DISPATCH_FAILED = "DISPATCH_FAILED"
    AUTHENTICATION_FAILED = "AUTHENTICATION_FAILED"
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED"
    INTERNAL_ERROR = "INTERNAL_ERROR"


def error_response(
    status_code: int,
    error_code: str,
    message: str,
    details: Optional[Dict[str, Any]] = None
) -> JSONResponse:
    """Create a standardized error response"""
    content = {
        "success": False,
        "error": {
            "code": error_code,
            "message": message
        }
    }
    
    if details:
        content["error"]["details"] = details
        
    return JSONResponse(
        status_code=status_code,
        content=content
    )


def success_response(
    data: Any,
    metadata: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """Create a standardized success response"""
    response = {
        "success": True,
        "data": data
    }
    
    if metadata:
        response["metadata"] = metadata
        
    return response


# HTTP exception handlers for the FastAPI app

def register_exception_handlers(app):
    """Register exception handlers for the FastAPI app"""
    
    @app.exception_handler(HTTPException)
    async def http_exception_handler(request, exc):
        """Handle HTTPException"""
        logger.warning(f"HTTP exception: {exc.status_code} - {exc.detail}")
        
        # Map common status codes to error codes
        error_code = ErrorCode.INTERNAL_ERROR
        
        if exc.status_code == status.HTTP_404_NOT_FOUND:
            error_code = ErrorCode.MODEL_NOT_FOUND
        elif exc.status_code == status.HTTP_401_UNAUTHORIZED:
            error_code = ErrorCode.AUTHENTICATION_FAILED
        elif exc.status_code == status.HTTP_403_FORBIDDEN:
            error_code = ErrorCode.AUTHENTICATION_FAILED
        elif exc.status_code == status.HTTP_429_TOO_MANY_REQUESTS:
            error_code = ErrorCode.RATE_LIMIT_EXCEEDED
        elif exc.status_code == status.HTTP_400_BAD_REQUEST:
            error_code = ErrorCode.INVALID_REQUEST
        elif exc.status_code == status.HTTP_503_SERVICE_UNAVAILABLE:
            error_code = ErrorCode.MODEL_NOT_AVAILABLE
            
        return error_response(
            status_code=exc.status_code,
            error_code=error_code,
            message=exc.detail
        )
        
    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request, exc):
        """Handle unhandled exceptions"""
        logger.error(f"Unhandled exception: {str(exc)}", exc_info=True)
        
        return error_response(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            error_code=ErrorCode.INTERNAL_ERROR,
            message="An unexpected error occurred",
            details={"error_type": type(exc).__name__}
        )