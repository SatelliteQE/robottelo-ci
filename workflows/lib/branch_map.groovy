branch_map = [
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
    'SATELLITE-6.5.0': [
        'repo': 'Satellite 6.5 Source Files',
        'version': '6.5.0',
        'tool_belt_config': './configs/satellite/',
        'foreman_branch': '1.20-stable',
        'ruby': '2.5',
        'packaging_job': 'sat-65-satellite-packaging-update'
    ],
    'SATELLITE-6.6.0': [
        'repo': 'Satellite 6.6 Source Files',
        'version': '6.6.0',
        'tool_belt_config': './configs/satellite/',
        'foreman_branch': 'develop',
        'ruby': '2.5',
        'packaging_job': 'sat-66-satellite-packaging-update'
    ],
    'SATELLITE-6.7.0': [
        'repo': 'Satellite 6.7 Source Files',
        'version': '6.7.0',
        'tool_belt_config': './configs/satellite/',
        'foreman_branch': 'develop',
        'ruby': '2.5',
        'packaging_job': 'sat-67-satellite-packaging-update'
    ],
    'SATELLITE-6.8.0': [
        'repo': 'Satellite 6.8 Source Files',
        'version': '6.8.0',
        'tool_belt_config': './configs/satellite/',
        'foreman_branch': 'develop',
        'ruby': '2.5',
        'packaging_job': 'sat-68-satellite-packaging-update'
    ],
    'RHUI-3.0.0': [
        'repo': 'RHUI 3.0 Source Files',
        'version': '3.0.0',
        'tool_belt_config': './configs/rhui/',
        'packaging_job': 'rhui-3-rhui-packaging-update'
    ],
    'master': [
        'version': '6.8.0',
        'tool_belt_config': './configs/satellite/',
        'foreman_branch': 'develop',
        'ruby': '2.5',
        'packaging_job': null
    ]
]
