import os
import subprocess
import pipes
import yaml

str = open("./cloud-init-yaml.yaml").read()
doc = yaml.load(str)
print(doc["package_update"])
