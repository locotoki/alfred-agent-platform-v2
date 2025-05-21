Alfred Docstring Templates
=======================

This document provides standard docstring templates and examples for the Alfred platform.
All code in the repo should follow these Google-style docstring formats to ensure consistency
and support the D400, D401, and D403 rules.

Module Docstrings
----------------

.. code-block:: python

    """Module purpose description ending with a period.

    This module provides [specific functionality] for [specific component].
    It implements [specific design patterns/algorithms] to [achieve specific goal].

    Longer descriptions can span multiple paragraphs if needed.
    """

Class Docstrings
---------------

.. code-block:: python

    class SomeClass:
        """Short description of the class ending with a period.

        Detailed description of the class purpose and functionality.

        Attributes:
            attr_name: Description of the attribute.
            another_attr: Another attribute description.
        """

Method and Function Docstrings
----------------------------

Note the imperative mood ('Do something', not 'Does something' or 'It does something'):

.. code-block:: python

    def some_function(param1, param2=None):
        """Return something based on input parameters.

        Detailed description of what the function does.

        Args:
            param1: Description of first parameter.
            param2: Description of second parameter. Default is None.
                    For longer descriptions, indent continuation lines.

        Returns:
            Return value description.

        Raises:
            ExceptionType: When and why this exception is raised.
        """

Property Docstrings
-----------------

.. code-block:: python

    @property
    def some_property(self):
        """Return the property value.

        Further description if needed.
        """
        return self._some_property

Special Cases
-----------

For simple properties or very short methods (< 5 lines) used only internally, you may use:

.. code-block:: python

    def _short_internal_helper(x):
        """Return doubled input value."""  # One-line is fine for simple functions
        return x * 2

    @property
    def minor_property(self):
        """Return the thing."""  # No need for extensive docs
        return self._thing

Remember:
* First line must end with a period (D400)
* First line should be in imperative mood (D401)
* First line should not be the function name (D403)

Proper imperative verbs to start docstrings:
* "Return" (not "Returns")
* "Initialize" (not "Initializes")
* "Create" (not "Creates")
* "Calculate" (not "Calculates")
* "Process" (not "Processes")
* "Generate" (not "Generates")
* "Parse" (not "Parses")
