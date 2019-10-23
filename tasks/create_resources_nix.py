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
        data = args['data'][0]['result']
        for i in data['resources']:
            params = i['parameters']
            print("dsc_{} {{ '{}' :".format(i['resource'], i['name']))
            for p in params:
                for k,v in p.items():
                    print("  dsc_{} => '{}',".format(k,v))
            print("}")
        if args['show_warnings'] == True:
            print("WARNINGS FROM GPO EXPORT: ")
            for warning in data['warnings']:
                print("  - {}".format(warning))
            print("Note: Warnings come from the BaselineManagement powershell module.")

if __name__ == '__main__':
    CreateResources().run()

