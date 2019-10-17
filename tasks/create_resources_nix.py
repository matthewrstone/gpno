#!/usr/bin/env python
import os, sys
import json

sys.path.append(
    os.path.join(os.path.dirname(__file__), '..', '..',
    'python_task_helper', 'files')
)

from task_helper import TaskHelper

class CreateResources(TaskHelper):
    def task(self, args):
        data = args['data'][0]['result']['resources']
        for i in data:
            params = i['parameters']
            print("dsc_{} {{ '{}' :".format(i['resource'], i['name']))
            for p in params:
                for k,v in p.items():
                    print("  dsc_{} => '{}',".format(k,v))
            print("}")

if __name__ == '__main__':
    CreateResources().run()

