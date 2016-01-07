#!/usr/bin/env python
"""mock_config/composition.py - Objects for composing Mock cinfiguration from
multipile objects
"""


class Composit(list):
    """Class for composing Mock configuration from multiple configuration
    objects.

    Configuration objects are objects that can either be converted to a Mock
    configuration string with 'str' or have the 'body' method which returns a
    Mock configuration string.
    The configuration object can also optionally contain the 'initialization'
    and 'finalization' methods to be called to gnenerate additional
    configuration strings. During the composition process the 'body',
    'initialization' and 'finalization' methods will be passed the
    'composition_context' dictionary which is a shared dictionary passed to all
    confiruration objects to allow sharing of configuration state.

    The composition process is preformed upon conversion to string, it is done
    in the following stages:
    1. 'initialization' is called for all the configuration objects that have it
       in the order they were added to the Composit
    2. 'body' is called for all the configuration object that have it, in the
       order they were added to the Composit. Objects that don't have the 'body'
       methos are converted to string using 'str'
    3. 'finalization' is called for all the configuration objects that have it
       in revers order to the one in which they were added to the Composit
    The returned values from all the method calls above are concatenated with
    newlines between them into one string which is returned.

    Objects of this class can also be passed as configuration objects to other
    objects of this class
    """
    def __init__(self, *config_objects):
        """Allow initializing with var-args for some conveniance syntax for
        one-liner compositing

        :param list config_objects: Configuration objects to compose together

        Configuration object can be strings. See class doctext for more detailed
        description of configuration objects
        """
        super(Composit, self).__init__(config_objects)

    def initialization(self, composition_context):
        """Generate composit configuration initialization code"""
        return '\n'.join(
            str(conf_obj.initialization(composition_context))
            for conf_obj in self if hasattr(conf_obj, 'initialization')
        )

    def body(self, composition_context):
        """Generate composit configuration body code"""
        return '\n'.join(
            str(conf_obj.body(composition_context)) if hasattr(conf_obj, 'body')
            else str(conf_obj)
            for conf_obj in self
        )

    def finalization(self, composition_context):
        """Generate composit configuration finalization code"""
        return '\n'.join(
            str(conf_obj.finalization(composition_context))
            for conf_obj
            in reversed([
                conf_obj for conf_obj in self
                if hasattr(conf_obj, 'finalization')
            ])
        )

    def __str__(self):
        """Preform to composition process and return the composit configuration
        as described in the class doctext
        """
        composition_context = {}
        return '\n'.join(filter(None, (
            self.initialization(composition_context),
            self.body(composition_context),
            self.finalization(composition_context)
        )))


compose = Composit  # syntactic sugar


class ConfigurationObject(object):
    """A "Base Class" to make it convenient to create configuration objects as
    described by the Composit class docstring

    Conatains a convenient implementation of __str__ and a quick way to create
    the various methods if they return plain strings
    """
    ALL_METHODS = ('initialization', 'body', 'finalization')

    def __init__(self, initialization=None, body=None, finalization=None):
        """Initialize the configuration object

        :param str initialization: Optional string to return from the
                                   initialization method
        :param str body: Optional string to return from the
                         body method
        :param str finalization: Optional string to return from the
                                 finalization method

        If None is passed to one of the methos arguments, that method will not
        be created for the object
        """
        for method in self.ALL_METHODS:
            method_val = locals().get(method, None)
            if method_val is not None:
                def phase_method(self, composition_context, value=method_val):
                    return value
                setattr(self, method, phase_method.__get__(self))

    def __str__(self):
        """Return a configuration string built with the methods the object has
        in a psudo compozition process
        """
        composition_context = {}
        return '\n'.join(filter(None, (
            getattr(self, method)(composition_context)
            for method in self.ALL_METHODS if hasattr(self, method)
        )))
