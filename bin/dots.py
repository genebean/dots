import platform

my_platform=platform.platform().lower()
if 'darwin' in my_platform:
    mac_version=platform.mac_ver()[0].split('.')
    if int(mac_version[0]) == 10 and int(mac_version[1]) >= 12:
        print("It seems you are on macOS")
    elif int(mac_version[0]) == 10 and int(mac_version[1]) < 12:
        print("It seems you are on OS X")
    else:
        print("What tha... you're Apple is pre-OS X (" + platform.mac_ver()[0] + " to be exact)" )
elif 'linux' in my_platform:
    print("It seems you are on Linux")
else:
    print("Not sure what OS you are on but here's what I see: " + my_platform)

