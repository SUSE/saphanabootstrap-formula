#!py
import platform

PLATFORMS = {
    'x86_64': 'HDB_CLIENT_LINUX_X86_64',
    'ppc64': 'HDB_CLIENT_LINUX_PPC64',
    'ppc64le': 'HDB_CLIENT_LINUX_PPC64LE'
}

def run():
      """
      Get the SAP HANA installation folder by platform
      """
      current_platform = platform.machine()
      try:
          return PLATFORMS[current_platform]
      except KeyError:
          raise KeyError('not supported platform: {}'.format(current_platform))
