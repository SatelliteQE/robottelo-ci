def branch_map = [
    'SATELLITE-6.2.0': [
        'repo': 'Satellite 6.2 Source Files',
        'version': '6.2.0',
        'tool_belt_config': './configs/satellite/',
        'foreman_branch': '1.11-stable',
        'ruby': '2.0',
        'packaging_job': null
    ],
    'SATELLITE-6.3.0': [
        'repo': 'Satellite 6.3 Source Files',
        'version': '6.3.0',
        'tool_belt_config': './configs/satellite/',
        'foreman_branch': '1.15-stable',
        'ruby': '2.3',
        'packaging_job': 'sat-63-satellite-packaging-update'
    ],
    'SATELLITE-6.4.0': [
        'repo': 'Satellite 6.4 Source Files',
        'version': '6.4.0',
        'tool_belt_config': './configs/satellite/',
        'foreman_branch': '1.18-stable',
        'ruby': '2.4',
        'packaging_job': 'sat-64-satellite-packaging-update'
    ],
    'RHUI-3.0.0': [
        'repo': 'RHUI 3.0 Source Files',
        'version': '3.0.0',
        'tool_belt_config': './configs/rhui/',
        'packaging_job': 'rhui-3-rhui-packaging-update'
    ]
]
