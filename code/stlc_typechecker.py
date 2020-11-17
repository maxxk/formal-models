from dataclasses import dataclass
from typing import Union, List, Optional, Any
from abc import ABC

Type = Union["Bool", "Arrow"]

@dataclass
class Bool: pass
@dataclass
class Arrow:
    left: Type
    right: Type

class TermMixin(ABC):
    def __mul__(self: Any, other: "Term"):
        return Call(self, other)
    def __div__(self: Any, other: Type):
        return HasType(self, other)

Term = Union["Value", "Variable", "Function", "Call", "HasType"]

@dataclass
class Value(TermMixin): value: bool

@dataclass
class Variable(TermMixin): name: str

@dataclass
class Function(TermMixin):
    argument: Variable
    body: Term
λ = Function

@dataclass
class Call(TermMixin):
    function: Term
    argument: Term

@dataclass
class HasType(TermMixin):
    term: Term
    hint: Type

@dataclass
class Judgement:
    variable: Variable
    given_type: Type

Context = List[Judgement]

def check(context: Context, term: Term, type: Type):
    if isinstance(term, Function) and isinstance(type, Arrow):
        return check(context + [Judgement(term.argument, type.left)], term.body, type.right)

    if infer(context, term) != type:
        raise TypeError

def infer(context: Context, term: Term) -> Type:
    if isinstance(term, Value): return Bool()
    if isinstance(term, Variable):
        found = next((entry.given_type for entry in context if entry.variable == term), None)
        if not found: raise TypeError
        return found
    if isinstance(term, Call):
        function_type = infer(context, term.function)
        if not isinstance(function_type, Arrow): raise TypeError
        check(context, term.argument, function_type.left)
        return function_type.right
    if isinstance(term, HasType):
        check(context, term.term, term.hint)
        return term.hint
    raise TypeError
