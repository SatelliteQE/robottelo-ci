# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Inspired from: https://github.com/redhat-openstack/khaleesi/blob/master/plugins/callbacks/human_log.py
# Further improved support Ansible 2.0

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

try:
    import simplejson as json
except ImportError:
    import json

# Fields to reformat output for
FIELDS = ['cmd', 'command', 'start', 'end', 'delta', 'msg', 'stdout', 'module_stderr',
          'stderr', 'results']


class CallbackModule(object):

    """
    Ansible callback plugin for human-readable result logging
    """
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'notification'
    CALLBACK_NAME = 'human_log'
    CALLBACK_NEEDS_WHITELIST = False

    def human_log(self, data):
        if type(data) == dict:
            for field in FIELDS:
                no_log = data.get('_ansible_no_log')
                if field in data.keys() and data[field] and no_log != True:
                    output = self._format_output(data[field])
                    print("\n{0}: {1}".format(field, output.replace("\\n","\n")))

    def _format_output(self, output):
        # Strip unicode
        if type(output) == unicode:
            output = output.encode('ascii', 'replace')

        # If output is a dict
        if type(output) == dict:
            return json.dumps(output, indent=2)

        # If output is a list of dicts
        if type(output) == list and type(output[0]) == dict:
            # This gets a little complicated because it potentially means
            # nested results, usually because of with_items.
            real_output = list()
            for index, item in enumerate(output):
                copy = item
                if type(item) == dict:
                    for field in FIELDS:
                        if field in item.keys():
                            copy[field] = self._format_output(item[field])
                real_output.append(copy)
            return json.dumps(output, indent=2)

        # If output is a list of strings
        if type(output) == list and type(output[0]) != dict:
            # Strip newline characters
            real_output = list()
            for item in output:
                if "\n" in item:
                    for string in item.split("\n"):
                        real_output.append(string)
                else:
                    real_output.append(item)

            # Reformat lists with line breaks only if the total length is
            # >75 chars
            if len("".join(real_output)) > 75:
                return "\n" + "\n".join(real_output)
            else:
                return " ".join(real_output)

        # Otherwise it's a string, (or an int, float, etc.) just return it
        return str(output)

    def on_any(self, *args, **kwargs):
        pass

    def runner_on_failed(self, host, res, ignore_errors=False):
        self.human_log(res)

    def runner_on_ok(self, host, res):
        self.human_log(res)

    def runner_on_skipped(self, host, item=None):
        pass

    def runner_on_unreachable(self, host, res):
        self.human_log(res)

    def runner_on_no_hosts(self):
        pass

    def runner_on_async_poll(self, host, res, jid, clock):
        self.human_log(res)

    def runner_on_async_ok(self, host, res, jid):
        self.human_log(res)

    def runner_on_async_failed(self, host, res, jid):
        self.human_log(res)

    def playbook_on_start(self):
        pass

    def playbook_on_notify(self, host, handler):
        pass

    def playbook_on_no_hosts_matched(self):
        pass

    def playbook_on_no_hosts_remaining(self):
        pass

    def playbook_on_task_start(self, name, is_conditional):
        pass

    def playbook_on_vars_prompt(self, varname, private=True, prompt=None, encrypt=None, confirm=False, salt_size=None, salt=None, default=None):
        pass

    def playbook_on_setup(self):
        pass

    def playbook_on_import_for_host(self, host, imported_file):
        pass

    def playbook_on_not_import_for_host(self, host, missing_file):
        pass

    def playbook_on_play_start(self, name):
        pass

    def playbook_on_stats(self, stats):
        pass

    def on_file_diff(self, host, diff):
        pass


    ####### V2 METHODS ######
    def v2_on_any(self, *args, **kwargs):
        pass

    def v2_runner_on_failed(self, result, ignore_errors=False):
        self.human_log(result._result)

    def v2_runner_on_ok(self, result):
        self.human_log(result._result)

    def v2_runner_on_skipped(self, result):
        pass

    def v2_runner_on_unreachable(self, result):
        self.human_log(result._result)

    def v2_runner_on_no_hosts(self, task):
        pass

    def v2_runner_on_async_poll(self, result):
        self.human_log(result._result)

    def v2_runner_on_async_ok(self, host, result):
        self.human_log(result._result)

    def v2_runner_on_async_failed(self, result):
        self.human_log(result._result)

    def v2_playbook_on_start(self, playbook):
        pass

    def v2_playbook_on_notify(self, result, handler):
        pass

    def v2_playbook_on_no_hosts_matched(self):
        pass

    def v2_playbook_on_no_hosts_remaining(self):
        pass

    def v2_playbook_on_task_start(self, task, is_conditional):
        pass

    def v2_playbook_on_vars_prompt(self, varname, private=True, prompt=None,
                                   encrypt=None, confirm=False, salt_size=None,
                                   salt=None, default=None):
        pass

    def v2_playbook_on_setup(self):
        pass

    def v2_playbook_on_import_for_host(self, result, imported_file):
        pass

    def v2_playbook_on_not_import_for_host(self, result, missing_file):
        pass

    def v2_playbook_on_play_start(self, play):
        pass

    def v2_playbook_on_stats(self, stats):
        pass

    def v2_on_file_diff(self, result):
        pass

    def v2_playbook_on_item_ok(self, result):
        pass

    def v2_playbook_on_item_failed(self, result):
        pass

    def v2_playbook_on_item_skipped(self, result):
        pass

    def v2_playbook_on_include(self, included_file):
        pass

    def v2_playbook_item_on_ok(self, result):
        pass

    def v2_playbook_item_on_failed(self, result):
        pass

    def v2_playbook_item_on_skipped(self, result):
	pass

# Save as <folder with your playbook>/callback_plugins/<some name>.py
# Optionally use no_log: True on your playbook/roles/tasks to suppress other output

#from __future__ import (absolute_import, division, print_function)
#__metaclass__ = type
#
#import os
#import time
#import json
#import sys
#from ansible.utils.unicode import to_bytes
#from ansible.plugins.callback import CallbackBase
#import pprint
#
#class CallbackModule(CallbackBase):
#    """
#    logs playbook results, per host, in /var/log/ansible/hosts
#    """
#    CALLBACK_VERSION = 2.0
#    CALLBACK_TYPE = 'notification'
#    CALLBACK_NAME = 'log_plays'
#
#    TIME_FORMAT="%b %d %Y %H:%M:%S"
#    MSG_FORMAT="%(now)s - %(category)s - %(data)s\n\n"
#
#    def __init__(self):
#
#        super(CallbackModule, self).__init__()
#
#    def log(self, host, category, data):
#        pp = pprint.PrettyPrinter(indent=2, stream=sys.stdout)
#        pp.pprint(data)
#
#    def runner_on_failed(self, host, res, ignore_errors=False):
#        self.log(host, 'FAILED', res)
#
#    def runner_on_ok(self, host, res):
#        self.log(host, 'OK', res)
#
#    def runner_on_skipped(self, host, item=None):
#        self.log(host, 'SKIPPED', '...')
#
#    def runner_on_unreachable(self, host, res):
#        self.log(host, 'UNREACHABLE', res)
#
#    def runner_on_async_failed(self, host, res, jid):
#        self.log(host, 'ASYNC_FAILED', res)
#
#    def playbook_on_import_for_host(self, host, imported_file):
#        self.log(host, 'IMPORTED', imported_file)
#
#    def playbook_on_not_import_for_host(self, host, missing_file):
#        self.log(host, 'NOTIMPORTED', missing_file)
