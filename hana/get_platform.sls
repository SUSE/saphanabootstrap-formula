#!py
from shaptools import hana

def run():
      """
      Get the SAP HANA installation folder by platform
      """
      return hana.HanaInstance.get_platform()
