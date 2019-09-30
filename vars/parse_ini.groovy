def call(Object param = [:], Map args = [:]) {
/*
   Usage:
   parse_ini ini_file: "${WORKSPACE}/robottelo.properties" , properties: ['hostname': 'host.x.z',
                                                                         '[vlan_networking]': '',
                                                                         'subnet': '192.168.0.1',
                                                                         'netmask': '24',
                                                                         'bridge': 'bridge_name',
                                                                         'gateway': '192.168.0.254'
                                                                          ]
*/
    // Get the properties key, value map
    if (args in Map) args = [properties: args]
    // Get the absolute file path
    if (param in String) param = [ini_file : param]
    in_file = param.get('ini_file','')
    propsFileText = readFile in_file
    def properties = param.get('properties',[:])
    // Iterate on all the items and replace them in ini file
    for (item in properties){
        if (! item.value) {
            propsFileText = propsFileText.replace("# ${item.key}", item.key)
        }
        else {
            propsFileText = propsFileText.replace("# ${item.key}=", "${item.key}=")
            propsFileText = propsFileText.replaceFirst(/${item.key}.*=.*/, "${item.key}=${item.value}")
            }
        }
    writeFile file: in_file , text: propsFileText
}
