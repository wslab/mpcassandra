import os
import subprocess
import pipes
import yaml

class public_key_string(str):
  pass

def pks_representer(dumper, data):
  style = '|'
  tag = u'tag:yaml.org,2002:str'
  return dumper.represent_scalar(tag, data, style=style)

def load_file_as_pks(filename):
  str = open(filename).read()
  return public_key_string(str)

def load_file_as_gzip_base64(filename):
  command = f"gzip -c {filename} | base64"
  out = subprocess.run(command, shell=True, stdout=subprocess.PIPE)
  return public_key_string(out.stdout.decode("utf-8"))


#packages that will be installed on the instance
packages = [ "openjdk-8-jdk-headless", "cassandra" ]

cassandra_key = load_file_as_pks("./files/cassandra-key.txt")

# bootcmd runs early in the boot process
bootcmd = [ 'echo $(whoami) > /root/boot.txt']

# runcmd is similar to rc.local
runcmd = [
  'chown ubuntu:ubuntu /home/ubuntu',
  'systemctl stop cassandra',
  # 'bash /root/set-seeds.sh'
  'mv /etc/cassandra/cassandra.yaml /etc/cassandra/cassandra.yaml.orig',
  'cp /root/cassandra.yaml /etc/cassandra/cassandra.yaml',
  '/root/set-listen-address.sh'
]

# file contents
set_seeds_contents = load_file_as_pks('./files/set-seeds.sh')
import_seeds_contents = load_file_as_pks('./files/import-seeds.sh')
cassandra_yaml_contents = load_file_as_gzip_base64('./files/cassandra.yaml')
set_listed_address_contents = load_file_as_pks("./files/set-listen-address.sh")

# files
set_seeds_file = { 
  'path': '/root/set-seeds.sh', 
  'permissions': '0755',
  'owner': 'root',
  'content': set_seeds_contents
}

import_seeds_file = { 
  'path': '/root/import-seeds.sh', 
  'permissions': '0755',
  'owner': 'root',
  'content': import_seeds_contents
}

set_listed_address_file = { 
  'path': '/root/set-listen-address.sh', 
  'permissions': '0755',
  'owner': 'root',
  'content': set_listed_address_contents
}

dummy_file = { 
  'path': '/home/ubuntu/file.txt', 
  'permissions': '06444',
  'owner': 'ubuntu:ubuntu',
  'content': 'my dummy content'
}

cassandra_yaml_file = {
  'path': '/root/cassandra.yaml', 
  'permissions': '0644',
  'owner': "root",
  'encoding': 'gzip+base64',
  'content': cassandra_yaml_contents
}

yaml.add_representer(public_key_string, pks_representer, Dumper=yaml.SafeDumper)

config = {}
config["package_update"] = True
cassandra_source_list = { 
    'source': "deb https://downloads.apache.org/cassandra/debian 311x main", 
    "key": cassandra_key
    }
config["apt"] = { 'sources': {'cassandra.sources.list': cassandra_source_list}}
config["packages"] = packages
config["write_files"] = [ 
  set_seeds_file, 
  import_seeds_file,
  set_listed_address_file,
  # dummy_file, 
  cassandra_yaml_file 
]
config["bootcmd"] = bootcmd
config["runcmd"] = runcmd
print(yaml.safe_dump(config, default_flow_style=False))
