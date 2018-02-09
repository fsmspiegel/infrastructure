#!/usr/bin/env python

import argparse
from contextlib import closing
import hashlib
import os
import sys
import shutil
import tarfile
import urllib2


def download(url):
    file_name = url.split('/')[-1]
    print 'Downloading: ' + file_name
    with closing(urllib2.urlopen(url)) as page:
        block_sz = 8912
        with open(file_name, 'wb') as f:
            while True:
                buffer = page.read(block_sz)
                if not buffer:
                    break
                f.write(buffer)
    return os.path.join(os.getcwd(),file_name)

def calculate_md5(file):
    with open(file) as f:
        data = f.read()
        md5_result = hashlib.md5(data).hexdigest()
    return md5_result.strip()

def read_md5(file):
    with open(file) as f:
        md5_result = f.readline()
    return md5_result.strip()

def untar(tar_file):
    if tarfile.is_tarfile(tar_file):
        with tarfile.open(tar_file, 'r:gz') as tar:
            tar.extractall()
            print 'Extracted in current directory'
            return os.path.dirname(os.path.abspath(__file__))

def move_site(src, dest):
    destination = '/var/www/' + dest
    try:
        for filename in os.listdir(src):
            shutil.move(os.path.join(src,filename),
                        os.path.join(destination,filename))
            print "Moving {0} to {1} ".format(filename, destination)
    except Exception as e:
        sys.exit(e)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--hash', action='store', type=str, nargs='?',
                        help='Hash of the commit to deploy')
    parser.add_argument('--url', action='store', type=str,
                        help='URL where files will be downloaded')
    parser.add_argument('--domain', action='store', type=str, nargs='?',
                        help='The domain to prepend [eg. https://$domain.eyeofiles.com')
    parser.add_argument('--website', action='store', type=str, nargs='?',
                        help='The name of the website [e.g. help.eyeo.com]')
    args = parser.parse_args()
    hash = args.hash
    domain = args.domain
    if args.url:
        url_file = '{0}{1}.tar.gz'.format(url, hash)
        url_md5 = '{0}{1}.md5'.format(url, hash)
    else:
        url_file = 'https://{0}.eyeofiles.com/{1}.tar.gz'.format(domain, hash)
        url_md5 = 'https://{0}.eyeofiles.com/{1}.md5'.format(domain, hash)

    down_file = download(url_file)
    down_md5 = download(url_md5)
    if calculate_md5(down_file) == read_md5(down_md5):
        tar_directory = untar(down_file)
        hash_directory = os.path.join(tar_directory, hash)
        move_site(hash_directory, args.website)
    else:
        sys.exit("Hashes don't match")


