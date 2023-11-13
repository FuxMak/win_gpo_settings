#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = r'''
---
module: win_gpo_settings
short_description: Edits the settings of Group Policy Objects (GPOs) on an Active Directory domain controller
description:
  - Edits Group Policy entries on an Active Directory domain controller using PowerShell.
  - Creates the specified Group Policy Object if it does not yet exist
  - Uses the GroupPolicy PowerShell module.
options:
  gpo_name:
    description:
      - Name of the Group Policy Object (GPO) to be edited.
    type: str
    required: yes
  key_path:
    description:
      - Path to the registry key to be modified.
      - Must begin with either HKEY_CURRENT_USER or HKEY_LOCAL_MACHINE.
    type: str
    required: yes
  gpo_value_name:
    description:
      - Name of the registry value to be modified.
    type: str
    required: yes
  gpo_value:
    description:
      - Desired value for the registry entry.
    type: str
  key_type:
    description:
      - Type of the registry key to be modified.
      - Valid choices are "String", "ExpandString", "Binary", "DWord", "MultiString", "QWord".
    type: str
    choices: ["String", "ExpandString", "Binary", "DWord", "MultiString", "QWord"]
  state:
    description:
      - State of the registry key.
      - If 'present', the key will be added or updated to the specified value.
      - If 'absent', the key will be removed.
      - If 'disabled', the key will be present but disabled.
    type: str
    default: "present"
    choices: ["present", "absent", "disabled"]
seealso:
  - name: Microsoft Powershell Group Policy CMDlets
    description: Complete reference of the powershell CMDlets which are used in the module.
    link: https://learn.microsoft.com/en-us/powershell/module/grouppolicy/?view=windowsserver2022-ps
  - name: Microsoft ADMX Template documentation
    description: Complete collection of registry hives and keys which can be used in the module to set group policy settings.
    link: https://admx.help/

author:
  - Marco Fuchs (https://github.com/FuxMak)
'''

EXAMPLES = r'''
- name: Modify GPO - Specify intranet Microsoft update service location (Policy enabled, setting enabled)
  win_gpo_settings:
    gpo_name: "Custom_WindowsUpdate"
    gpo_value_name: "UseWUServer"
    gpo_value: "1"
    key_path: "HKEY_LOCAL_MACHINE\\Software\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU"
    key_type: "DWord"
    state: present

- name: Modify GPO - Specify intranet Microsoft update service location (Policy enabled, setting disabled)
  win_gpo_settings:
    gpo_name: "Custom_WindowsUpdate"
    gpo_value_name: "UseWUServer"
    gpo_value: "0"
    key_path: "HKEY_LOCAL_MACHINE\\Software\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU"
    key_type: "DWord"
    state: present

- name: Modify GPO - Specify intranet Microsoft update service location (Policy disabled)
  win_gpo_settings:
    gpo_name: "Custom_WindowsUpdate"
    gpo_value_name: "UseWUServer"
    key_path: "HKEY_LOCAL_MACHINE\\Software\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU"
    state: disabled

- name: Modify GPO - Specify intranet Microsoft update service location - Set the intranet update service for detecting updates (Policy enabled, setting enabled - var: wsus_server)
  win_gpo_settings:
    gpo_name: "Custom_WindowsUpdate"
    gpo_value_name: "WUServer"
    gpo_value: "{{ wsus_server }}:8530"
    key_path: "HKEY_LOCAL_MACHINE\\Software\\Policies\\Microsoft\\Windows\\WindowsUpdate"
    key_type: "String"
    state: present

- name: Modify GPO - Specify intranet Microsoft update service location - Set the intranet update service for detecting updates (Policy unconfigured)
  win_gpo_settings:
    gpo_name: "Custom_WindowsUpdate"
    gpo_value_name: "WUServer"
    key_path: "HKEY_LOCAL_MACHINE\\Software\\Policies\\Microsoft\\Windows\\WindowsUpdate"
    state: absent
'''
