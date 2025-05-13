import os
import sys
from typing import Dict, List, Any, Optional

import json
import logging
import re
from datetime import datetime, timedelta

def badly_formatted_function( arg1, arg2 :str,arg3:  int=42 )->Dict[str, Any]:
    """This function has deliberately bad formatting to test CI checks."""
    result = { 'arg1': arg1, 'arg2':arg2, 'arg3':arg3 }
    
    if arg1 == "test":
      # Incorrect indentation
      nested_dict = {"key1":"value1",  "key2":"value2"}
      result["nested"] = nested_dict
    
    return     result

class BadlyFormattedClass:
    def __init__(self, name: str, value = None):
        self.name = name
        self.value=value
        
    def do_something(self,input_value:str)-> Optional[str]:
     # Bad indentation and spacing
     if input_value == "":
         return None
     else:
      transformed = input_value.upper()
      return transformed