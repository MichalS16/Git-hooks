# flake8_file.py
# Demonstrating the pre-commit Flake8 functionality.


# An example of bad code styling
# Comment/uncomment the following to see the Flake8 pre-commit:
"""
def add(a,b):
# E231: missing space after comma
  return(a+b)
# E211: whitespace before '(';
# E701: statement on the same line as return

x=add( 5,10)
# E201: extra spaces inside parentheses;
# E225: missing space around operator;
# E305 expected 2 blank lines after class or function definition, found 1
print(x)
"""


# An example of good code styling
# A correct version that passes Flake8 checks:
def add(a, b):
    return a + b


x = add(5, 10)
print(x)
